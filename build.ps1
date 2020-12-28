# TODO: Move to base image
Write-Host "Installing conan..."
choco install conan -y --no-progress
$env:Path += ";C:\Program Files\Conan\conan"
conan --version

# TODO: Move to base image
Write-Host "Installing git..."
choco install git -y --no-progress
$env:Path += ";C:\Program Files\Git\cmd"
git --version

Write-Host "Adding Mersive's Conan Remote Repository"
conan remote add mersive "https://artifactory.mersive.xyz/artifactory/api/conan/conan-mersive"
conan user ci-rustusbip -r mersive -p "$env:ARTIFACTORY_PASSWORD"

$SETTINGS_RELEASE = "-s build_type=Release"
$SETTINGS_DEBUG = "-s build_type=Debug"

$SETTINGS_ALL = $SETTINGS_DEBUG, $SETTINGS_RELEASE

function BasicBuild($libraryName, $libraryVersion, $libraryPath, $libraryOptions)
{
  foreach ($SETTINGS_CONFIGURATION in $SETTINGS_ALL) {
    Write-Host "Performing a build of [$libraryName] with version [$libraryVersion]:"
    pushd "recipes/$libraryName/$libraryPath"

    $COORDINATE="$libraryName/$libraryVersion@"
    Write-Host "Installing [$COORDINATE]"
    conan install . $COORDINATE "$libraryOptions" "$SETTINGS_CONFIGURATION"

    Write-Host "Getting sources of [$COORDINATE]"
    conan source .

    Write-Host "Building [$COORDINATE]"
    conan build .

    Write-Host "Exporting [$COORDINATE]"
    conan export-pkg . "$COORDINATE" 

    Write-Host "Uploading [$COORDINATE]"
    conan upload "$COORDINATE" --all -c -r mersive

    Write-Host "Done building [$COORDINATE]!"

    git clean -xffd
    popd
  }
}

BasicBuild "zlib" $env:ZLIB_VERSION $env:ZLIB_VERSION
BasicBuild "protobuf" $env:PROTOBUF_VERSION "all"
