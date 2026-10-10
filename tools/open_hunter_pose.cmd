@echo off
setlocal
set "POSE_ROOT=%~dp0.."
set "POSE_BLENDER=%POSE_ROOT%\.tools\blender\blender-4.5.4-windows-x64\blender.exe"
set "POSE_SCENE=%POSE_ROOT%\prototypes\hunter_pose_workspace\hunter_pose.blend"
set "BLENDER_USER_CONFIG=%POSE_ROOT%\prototypes\hunter_pose_workspace\blender_config"
if not exist "%POSE_BLENDER%" (
  echo Khong tim thay Blender trong du an.
  pause
  exit /b 1
)
if not exist "%POSE_SCENE%" (
  echo Khong tim thay file hunter_pose.blend.
  pause
  exit /b 1
)
if not exist "%BLENDER_USER_CONFIG%\userpref.blend" (
  "%POSE_BLENDER%" --background --factory-startup --python-exit-code 1 --python "%POSE_ROOT%\tools\hunter_pose_preferences.py"
  if errorlevel 1 exit /b 1
)
start "" "%POSE_BLENDER%" "%POSE_SCENE%" --python "%POSE_ROOT%\tools\hunter_pose_ui.py"
endlocal
