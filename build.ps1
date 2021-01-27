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
Write-Host "Installing conan..."
choco install windows-sdk-8.1 -y --no-progress

# TODO: Move to base image
Write-Host "Installing git..."
choco install git -y --no-progress
$env:Path += ";C:\Program Files\Git\cmd"
git --version

Write-Host "Adding Mersive's Conan Remote Repository"
conan remote add mersive "https://artifactory.mersive.xyz/artifactory/api/conan/conan-mersive"
conan user ci-rustusbip -r mersive -p "$env:ARTIFACTORY_PASSWORD"

$SETTINGS_RELEASE_32 = "-sbuild_type=Release -sarch=x86"
$SETTINGS_RELEASE_64 = "-sbuild_type=Release -sarch=x86_64"
$SETTINGS_DEBUG_32 = "-sbuild_type=Debug -sarch=x86"
$SETTINGS_DEBUG_64 = "-sbuild_type=Debug -sarch=x86_64"

$SETTINGS_ALL = $SETTINGS_RELEASE_32,$SETTINGS_RELEASE_64,$SETTINGS_DEBUG_32,$SETTINGS_DEBUG_64

function BasicBuild($libraryName, $libraryVersion, $libraryPath, $libraryOptions)
{
  foreach ($SETTINGS_CONFIGURATION in $SETTINGS_ALL) {
    Write-Host "Performing a build of [$libraryName] with version [$libraryVersion]:"
    Push-Location "recipes/$libraryName/$libraryPath"

    $COORDINATE="$libraryName/$libraryVersion@"
    Write-Host "[$COORDINATE]: Installing"
    Invoke-Expression "conan install . $COORDINATE $libraryOptions $SETTINGS_CONFIGURATION"
    ErrorOnExeFailure

    Write-Host "[$COORDINATE]: Getting Sources"
    conan source .
    ErrorOnExeFailure

    Write-Host "[$COORDINATE]: Building"
    conan build .
    ErrorOnExeFailure

    Write-Host "[$COORDINATE]: Exporting Package"
    conan export-pkg --force . "$COORDINATE"
    ErrorOnExeFailure

    Write-Host "[$COORDINATE]: Uploading to Mersive Artifactory"
    conan upload "$COORDINATE" --all -c -r mersive
    ErrorOnExeFailure

    Write-Host "[$COORDINATE]: Cleaning Up"
    git clean -xffd
    ErrorOnExeFailure
    Pop-Location

    Write-Host "[$COORDINATE]: Done!"
  }
}

BasicBuild "zlib" "1.2.11" "1.2.11"
BasicBuild "libsodium" "1.0.18" "1.0.18"
BasicBuild "zeromq" "4.3.3" "all" "-o zeromq:shared=False"
BasicBuild "zeromq" "4.3.3" "all" "-o zeromq:shared=True"
BasicBuild "cppzmq" "4.7.1" "all"
BasicBuild "protobuf" "3.12.4" "all"
