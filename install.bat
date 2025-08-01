@echo off
echo Terrain Generator SketchUp Add-on Installer
echo ==========================================
echo.

REM Detect SketchUp version and installation path
set "SKETCHUP_PLUGINS="

REM Check for SketchUp 2025
if exist "%APPDATA%\SketchUp\SketchUp 2025\SketchUp\Plugins" (
    set "SKETCHUP_PLUGINS=%APPDATA%\SketchUp\SketchUp 2025\SketchUp\Plugins"
    echo Found SketchUp 2025
    goto :install
)

REM Check for SketchUp 2024
if exist "%APPDATA%\SketchUp\SketchUp 2024\SketchUp\Plugins" (
    set "SKETCHUP_PLUGINS=%APPDATA%\SketchUp\SketchUp 2024\SketchUp\Plugins"
    echo Found SketchUp 2024
    goto :install
)

REM Check for SketchUp 2023
if exist "%APPDATA%\SketchUp\SketchUp 2023\SketchUp\Plugins" (
    set "SKETCHUP_PLUGINS=%APPDATA%\SketchUp\SketchUp 2023\SketchUp\Plugins"
    echo Found SketchUp 2023
    goto :install
)

REM Check for SketchUp 2022
if exist "%APPDATA%\SketchUp\SketchUp 2022\SketchUp\Plugins" (
    set "SKETCHUP_PLUGINS=%APPDATA%\SketchUp\SketchUp 2022\SketchUp\Plugins"
    echo Found SketchUp 2022
    goto :install
)

REM Check for SketchUp 2021
if exist "%APPDATA%\SketchUp\SketchUp 2021\SketchUp\Plugins" (
    set "SKETCHUP_PLUGINS=%APPDATA%\SketchUp\SketchUp 2021\SketchUp\Plugins"
    echo Found SketchUp 2021
    goto :install
)

REM Check for SketchUp 2020
if exist "%APPDATA%\SketchUp\SketchUp 2020\SketchUp\Plugins" (
    set "SKETCHUP_PLUGINS=%APPDATA%\SketchUp\SketchUp 2020\SketchUp\Plugins"
    echo Found SketchUp 2020
    goto :install
)

REM Check for SketchUp 2019
if exist "%APPDATA%\SketchUp\SketchUp 2019\SketchUp\Plugins" (
    set "SKETCHUP_PLUGINS=%APPDATA%\SketchUp\SketchUp 2019\SketchUp\Plugins"
    echo Found SketchUp 2019
    goto :install
)

REM Check for SketchUp 2018
if exist "%APPDATA%\SketchUp\SketchUp 2018\SketchUp\Plugins" (
    set "SKETCHUP_PLUGINS=%APPDATA%\SketchUp\SketchUp 2018\SketchUp\Plugins"
    echo Found SketchUp 2018
    goto :install
)

REM Check for SketchUp 2017
if exist "%APPDATA%\SketchUp\SketchUp 2017\SketchUp\Plugins" (
    set "SKETCHUP_PLUGINS=%APPDATA%\SketchUp\SketchUp 2017\SketchUp\Plugins"
    echo Found SketchUp 2017
    goto :install
)

echo ERROR: SketchUp installation not found!
echo Please install SketchUp 2017 or later, or manually copy the files to your Plugins folder.
echo.
echo Manual installation path:
echo %APPDATA%\SketchUp\SketchUp [Version]\SketchUp\Plugins\
echo.
pause
exit /b 1

:install
echo.
echo Installing Terrain Generator to:
echo %SKETCHUP_PLUGINS%
echo.

REM Create plugins directory if it doesn't exist
if not exist "%SKETCHUP_PLUGINS%" (
    mkdir "%SKETCHUP_PLUGINS%"
)

REM Copy files
echo Copying terrain_generator_loader.rb...
copy "terrain_generator_loader.rb" "%SKETCHUP_PLUGINS%\" >nul
if errorlevel 1 (
    echo ERROR: Failed to copy terrain_generator_loader.rb
    goto :error
)

echo Copying terrain_generator.rb...
copy "terrain_generator.rb" "%SKETCHUP_PLUGINS%\" >nul
if errorlevel 1 (
    echo ERROR: Failed to copy terrain_generator.rb
    goto :error
)

echo Copying advanced_terrain.rb...
copy "advanced_terrain.rb" "%SKETCHUP_PLUGINS%\" >nul
if errorlevel 1 (
    echo ERROR: Failed to copy advanced_terrain.rb
    goto :error
)

echo Copying terrain_generator_2019.rb...
copy "terrain_generator_2019.rb" "%SKETCHUP_PLUGINS%\" >nul
if errorlevel 1 (
    echo ERROR: Failed to copy terrain_generator_2019.rb
    goto :error
)

echo.
echo ==========================================
echo Installation completed successfully!
echo ==========================================
echo.
echo The Terrain Generator add-on has been installed.
echo.
echo To use the add-on:
echo 1. Start SketchUp
echo 2. Go to Plugins ^> Terrain Generator
echo 3. Select your XYZ file and generate terrain
echo.
echo Your XYZ file is located at:
echo %~dp0..\python\01.Train\terrain.xyz
echo.
pause
exit /b 0

:error
echo.
echo ==========================================
echo Installation failed!
echo ==========================================
echo.
echo Please check that:
echo 1. SketchUp is not currently running
echo 2. You have write permissions to the Plugins folder
echo 3. The source files exist in the current directory
echo.
pause
exit /b 1
