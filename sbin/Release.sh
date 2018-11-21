#!/bin/bash
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

npm install

#             11 style version           | 8 Style                    | 9/10 style
versionRegex="[[:digit:]]{2}_[[:digit:]]+|8u[[:digit:]]+-?b[[:digit:]]+|[[:digit:]]+\.[[:digit:]]+\.[[:digit:]]+_[[:digit:]]+"
timestampRegex="[[:digit:]]{4}-[[:digit:]]{2}-[[:digit:]]{2}-[[:digit:]]{2}-[[:digit:]]{2}"

# IF YOU ARE MODIFYING THIS THEN THE FILE MATCHING IS PROBABLY WRONG, MAKE SURE openjdk-api, v2.js IS UPDATED TOO
#      OpenJDK 8U_             -jdk        x64_           Linux_         hotspot_         2018-06-15-10-10                .tar.gz
#      OpenJDK 11_             -jdk        x64_           Linux_         hotspot_         11_28                           .tar.gz
regex="OpenJDK([[:digit:]]+)U?(-jre|-jdk)_([[:alnum:]\-]+)_([[:alnum:]]+)_([[:alnum:]]+).*_($timestampRegex|$versionRegex).(tar.gz|zip)";
regexArchivesOnly="${regex}$";

# Date format is YYYY-MM-DD-hh-mm, i.e 2018-06-15-10-10.
# So files will look like:
#  OpenJDK8U_x64_Linux_hotspot_2018-06-15-10-10.tar.gz
#  OpenJDK8U_x64_Linux_hotspot_2018-06-15-10-10.tar.gz.sha256.txt
#  OpenJDK8U_x64_Linux_openj9_2018-06-15-10-10.tar.gz
#  OpenJDK8U_x64_Linux_openj9_2018-06-15-10-10.tar.gz.sha256.txt
TIMESTAMP="$(date -u +'%Y-%m-%d-%H-%M')"

# Rename to ensure a consistent timestamp across release
for file in OpenJDK*
do
  echo "Processing $file";

  if [[ $file =~ $regexArchivesOnly ]];
  then
    newName=$(echo "${file}" | sed -r "s/${timestampRegex}/$TIMESTAMP/")

    if [ "${file}" != "${newName}" ]; then
      # Rename archive and checksum file with new timestamp
      echo "Renaming ${file} to ${newName}"
      mv "${file}" "${newName}"
      mv "${file}.sha256.txt" "${newName}.sha256.txt"

    fi

    # Fix checksum file name
    sed -i -r "s/^([0-9a-fA-F ]+).*/\1${newName}/g" "${newName}.sha256.txt"

    FILE_VERSION=${BASH_REMATCH[1]};
    FILE_TYPE=${BASH_REMATCH[2]};
    FILE_ARCH=${BASH_REMATCH[3]};
    FILE_OS=${BASH_REMATCH[4]};
    FILE_VARIANT=${BASH_REMATCH[5]};
    FILE_TS_OR_VERSION=${BASH_REMATCH[6]};
    FILE_EXTENSION=${BASH_REMATCH[7]};

    echo "version:${FILE_VERSION} type: ${FILE_TYPE} arch:${FILE_ARCH} os:${FILE_OS} variant:${FILE_VARIANT} timestamp or version:${FILE_TS_OR_VERSION} timestamp:${TIMESTAMP} extension:${FILE_EXTENSION}";
  fi
done

files=`ls $PWD/OpenJDK*{.tar.gz,.sha256.txt,.zip} | sed -e ':a' -e 'N' -e '$!ba' -e 's/\n/ /g'`

echo "Release: $RELEASE"
if [ "$RELEASE" == "true" ]; then
  if [ -z "${TAG}" ]; then
    TAG="${TIMESTAMP}"
  fi
  TAG_NAME="$TAG_${TIMESTAMP}"
  node upload.js --files $files --tagName ${TAG_NAME} --tag ${TAG} --description "Official Release of $TAG" --release "$RELEASE"
else
  node upload.js --files $files --tagName ${TAG}-${TIMESTAMP} --tag ${TAG}-${TIMESTAMP} --description "Nightly Build of $TAG" --release "$RELEASE"
fi

node app.js
./sbin/gitUpdate.sh
