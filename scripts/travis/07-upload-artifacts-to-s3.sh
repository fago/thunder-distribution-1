#!/usr/bin/env bash
#
# Package and upload built Thunder project and database

# Package database
gzip < "${DEPLOYMENT_DUMP_FILE}" > "${DB_ARTIFACT_FILE}"

# Workaround for https://www.drupal.org/project/drupal/issues/3091285
chmod -R +w "${TEST_DIR}/docroot/sites/default"

# Include performance measurement module in artifact
cd "${TEST_DIR}"
composer require "thunder/thunder_performance_measurement:dev-master" "thunder/testsite_builder:dev-master" "drupal/media_entity_generic:^1.0" --no-interaction --update-no-dev

# Apply patches important for testsite_builder
cd "${TEST_DIR}/docroot" || exit
curl --silent "https://www.drupal.org/files/issues/2020-01-29/3109767_2.patch" | patch -p1

# Cleanup project
cd "${TEST_DIR}"
composer install --no-dev
rm -rf "${TEST_DIR}/bin"
rm -rf "${TEST_DIR}/docroot/sites/default/files/*"
rm -f "${DEPLOYMENT_DUMP_FILE}"
find "${TEST_DIR}" -type d -name ".git" | xargs rm -rf
find "${THUNDER_DIST_DIR}" -type d -name ".git" | xargs rm -rf

# Make zip for package
cd "${TEST_DIR}" && tar -czhf "${PROJECT_ARTIFACT_FILE}" .

# Upload files to S3 bucket
aws s3 cp "${DB_ARTIFACT_FILE}" "s3://thunder-builds/${DB_ARTIFACT_FILE_NAME}"
aws s3 cp "${PROJECT_ARTIFACT_FILE}" "s3://thunder-builds/${PROJECT_ARTIFACT_FILE_NAME}"
