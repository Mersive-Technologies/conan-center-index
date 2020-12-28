function ErrorOnExeFailure {
  if (-not $?)
  {
    throw 'Last EXE Call Failed!'
  }
}

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

$SETTINGS_RELEASE = "-sbuild_type=Release"
$SETTINGS_DEBUG = "-sbuild_type=Debug"

$SETTINGS_ALL = $SETTINGS_DEBUG,$SETTINGS_RELEASE

function BasicBuild($libraryName, $libraryVersion, $libraryPath, $libraryOptions)
{
  foreach ($SETTINGS_CONFIGURATION in $SETTINGS_ALL) {
    Write-Host "Performing a build of [$libraryName] with version [$libraryVersion]:"
    pushd "recipes/$libraryName/$libraryPath"

    $COORDINATE="$libraryName/$libraryVersion@"
    Write-Host "[$COORDINATE]: Installing"
    conan install . $COORDINATE "$libraryOptions" "$SETTINGS_CONFIGURATION"
    ErrorOnExeFailure

    Write-Host "[$COORDINATE]: Getting Sources"
    conan source .
    ErrorOnExeFailure

    Write-Host "[$COORDINATE]: Building"
    conan build .
    ErrorOnExeFailure

    Write-Host "[$COORDINATE]: Exporting Package"
    conan export-pkg . "$COORDINATE" 
    ErrorOnExeFailure

    Write-Host "[$COORDINATE]: Uploading to Mersive Artifactory"
    conan upload "$COORDINATE" --all -c -r mersive
    ErrorOnExeFailure

    Write-Host "[$COORDINATE]: Cleaning Up"
    git clean -xffd
    ErrorOnExeFailure
    popd

    Write-Host "[$COORDINATE]: Done!"
  }
}

BasicBuild "zlib" $env:ZLIB_VERSION $env:ZLIB_VERSION
BasicBuild "protobuf" $env:PROTOBUF_VERSION "all"
