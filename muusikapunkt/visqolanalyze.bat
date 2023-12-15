@echo off

set input_file=%1
set output_dir=output6
set svr_model_path=model\libsvm_nu_svr_model.txt

REM Create the output directory if it does not exist
if not exist "%output_dir%" mkdir "%output_dir%"

REM Downmixing to 2 channels using FFmpeg
ffmpeg -hide_banner -loglevel panic -i "%input_file%" -ac 2 -ar 48000 -c:a pcm_s16le -fflags +bitexact -flags:a +bitexact -map_metadata -1 -y "%output_dir%\stereo.wav"

REM AC3 Aften 0.0.8 and liba52 0.7.4
for %%A in (48 56 64 96 128 160 192 224 256 320) do (
  aften -b %%A "%output_dir%\stereo.wav" "%output_dir%\output_recons_%%A.ac3"
  a52dec -o wav "%output_dir%\output_recons_%%A.ac3" > "%output_dir%\output_eac3_%%A.wav"
  del /q "%output_dir%\output_recons_%%A.ac3"

  REM Visqol Analysis
  visqol --reference_file "%output_dir%\stereo.wav" --degraded_file "%output_dir%\output_eac3_%%A.wav" --similarity_to_quality_model "%svr_model_path%" --output_debug output_ac3-%%A.json > "%output_dir%\output_eac3_%%A_score.txt"
  for /f "tokens=2 delims=: " %%S in ('findstr /C:"MOS-LQO:" "%output_dir%\output_eac3_%%A_score.txt"') do (
   echo AC3 Aften a52dec at %%Ak bitrate: %%S
  )

  REM Clean up WAV files
  del "%output_dir%\output_eac3_%%A.wav"
)

for %%A in (48 56 64 96 128 160 192 224 256 320) do (
  aften -b %%A -w 60 "%output_dir%\stereo.wav" "%output_dir%\output_recons_%%A.ac3"
  a52dec -o wav "%output_dir%\output_recons_%%A.ac3" > "%output_dir%\output_eac3_%%A.wav"
  del /q "%output_dir%\output_recons_%%A.ac3"

  REM Visqol Analysis
  visqol --reference_file "%output_dir%\stereo.wav" --degraded_file "%output_dir%\output_eac3_%%A.wav" --similarity_to_quality_model "%svr_model_path%" --output_debug output_ac3-%%A-bandwidth.json > "%output_dir%\output_eac3_%%A_score.txt"
  for /f "tokens=2 delims=: " %%S in ('findstr /C:"MOS-LQO:" "%output_dir%\output_eac3_%%A_score.txt"') do (
   echo AC3 Aften a52dec bandwidth full at %%Ak bitrate: %%S
  )

  REM Clean up WAV files
  del "%output_dir%\output_eac3_%%A.wav"
)

REM Clean up the output directory
rmdir /s /q %output_dir%