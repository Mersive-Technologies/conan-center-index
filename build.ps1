# Write-Host "Installing conan..."
# choco install conan -y --no-progress
# $env:Path += ";C:\Program Files\Conan\conan"
# conan --version

# Write-Host "Adding Mersive's Conan Remote Repository"
# conan remote add mersive "https://artifactory.mersive.xyz/artifactory/api/conan/conan-mersive"
# conan user ci-rustusbip -r mersive -p "$env:ARTIFACTORY_PASSWORD"

function BasicBuild($libraryName, $libraryVersion, $libraryPath)
{
  Write-Host "Performing a build of [$libraryName] with version [$libraryVersion]:"
  pushd "recipes/$libraryName/$libraryPath"

  $COORDINATE="$libraryName/$libraryVersion@"
  Write-Host "Installing [$COORDINATE]"
  conan install .

  Write-Host "Getting sources of [$COORDINATE]"
  conan source .

  Write-Host "Building [$COORDINATE]"
  conan build .

  Write-Host "Exporting [$COORDINATE]"
  conan export-pkg . "$COORDINATE"

  Write-Host "Uploading [$COORDINATE]"
  # conan upload "$COORDINATE" --all -c -r mersive

  Write-Host "Done building [$COORDINATE]!"
  popd
}

# BasicBuild "zlib" $env:ZLIB_VERSION
BasicBuild "protobuf" $env:PROTOBUF_VERSION "all"
