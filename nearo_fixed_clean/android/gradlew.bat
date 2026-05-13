@echo off
REM Lightweight fallback wrapper for this generated package.
REM If Gradle is not available in PATH, run: flutter create . --platforms=android
gradle %*
