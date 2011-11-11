#!/bin/bash
set -x
BUILD_DIR="$(dirname $0)/build"
die() {
  echo $1
  exit 1
}

preflight_check() { 
  [ -z "${AWS_ACCESS_KEY_ID}" ] && die "I need an AWS_ACCESS_KEY_ID environment variable"
  [ -z "${AWS_SECRET_ACCESS_KEY}" ] && die "I need an AWS_SECRET_ACCESS_KEY environment variable"
  [ -z "${AWS_CALLING_FORMAT}" ] && die "I need an AWS_CALLING_FORMAT environment variable"
  # HINT: you can stick these in aws_secrets.sh
}

clean() {
  rm -f ${BUILD_DIR}/*.log
  rm -rf ${BUILD_DIR}/webalyzer
}

fetch_logs() {
  bucket=$1
  mkdir -p "${BUILD_DIR}/${bucket}/logs"
  s3sync.rb --make-dirs -r ${bucket}: "${BUILD_DIR}/${bucket}/logs"
}

process_s3() {
  host=$1
  bucket=$2
  find ${BUILD_DIR}/${bucket}/logs -name ${host}\* -type f  -exec cat {} >> ${BUILD_DIR}/${host}.log \;
  awk -f s3.awk ${BUILD_DIR}/${host}.log  > ${BUILD_DIR}/${host}.webalyzed.log
  mkdir -p ${BUILD_DIR}/webalyzer/${host}

  webalizer -o ${BUILD_DIR}/webalyzer/${host} ${BUILD_DIR}/$host.webalyzed.log  
}

process_cloudfront() {
  host=$1
  bucket=$2

  find ${BUILD_DIR}/${bucket}/logs/cloudfront.${host} -name \*.gz -exec gzip -cd  {} >> ${BUILD_DIR}/cloudfront.${host}.log \;
# we could avoid the dependency on ruby. I've been spoiled
  ruby date.rb < ${BUILD_DIR}/cloudfront.${host}.log | grep -v '^#' | awk -f cloudfront.awk > ${BUILD_DIR}/cloudfront.${host}.webalyzed.log
  mkdir -p ${BUILD_DIR}/webalyzer/cloudfront.${host}
  webalizer -o ${BUILD_DIR}/webalyzer/cloudfront.${host} ${BUILD_DIR}/cloudfront.${host}.webalyzed.log  
}
[ -f "aws_secrets.sh" ] && source aws_secrets.sh

[ "$#" -eq 2 ] || die "Usage: $0: <bucket_name> <hostname>"
bucket=$1; shift
s3host=$1; shift

preflight_check
fetch_logs $bucket
process_s3 $s3host $bucket
process_cloudfront $s3host $bucket
