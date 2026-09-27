#include "utils.h"

#include <flutter_windows.h>
#include <io.h>
#include <stdio.h>
#include <windows.h>

#include <chrono>
#include <fstream>
#include <iostream>
#include <sstream>

namespace {

std::string BuildRunnerLogLine(const std::string& message) {
  const auto now = std::chrono::system_clock::now().time_since_epoch();
  const auto millis =
      std::chrono::duration_cast<std::chrono::milliseconds>(now).count();
  std::ostringstream stream;
  stream << "[native-exit] t=" << millis
         << " pid=" << ::GetCurrentProcessId()
         << " tid=" << ::GetCurrentThreadId()
         << " " << message;
  return stream.str();
}

void AppendRunnerLogFile(const std::string& line) {
  wchar_t temp_path[MAX_PATH];
  const DWORD temp_path_length = ::GetTempPathW(MAX_PATH, temp_path);
  if (temp_path_length == 0 || temp_path_length > MAX_PATH) {
    return;
  }

  std::wstring log_path(temp_path);
  log_path += L"MemoFlow_native_exit.log";

  std::ofstream file(log_path, std::ios::app);
  if (!file.is_open()) {
    return;
  }
  file << line << std::endl;
  file.flush();
}

}  // namespace

void CreateAndAttachConsole() {
  if (::AllocConsole()) {
    FILE *unused;
    if (freopen_s(&unused, "CONOUT$", "w", stdout)) {
      _dup2(_fileno(stdout), 1);
    }
    if (freopen_s(&unused, "CONOUT$", "w", stderr)) {
      _dup2(_fileno(stdout), 2);
    }
    std::ios::sync_with_stdio();
    FlutterDesktopResyncOutputStreams();
  }
}

void RunnerLog(const std::string& message) {
  const std::string line = BuildRunnerLogLine(message);
  std::cerr << line << std::endl;
  std::cerr.flush();
  AppendRunnerLogFile(line);
  ::OutputDebugStringA((line + "\n").c_str());
}

std::vector<std::string> GetCommandLineArguments() {
  // Convert the UTF-16 command line arguments to UTF-8 for the Engine to use.
  int argc;
  wchar_t** argv = ::CommandLineToArgvW(::GetCommandLineW(), &argc);
  if (argv == nullptr) {
    return std::vector<std::string>();
  }

  std::vector<std::string> command_line_arguments;

  // Skip the first argument as it's the binary name.
  for (int i = 1; i < argc; i++) {
    command_line_arguments.push_back(Utf8FromUtf16(argv[i]));
  }

  ::LocalFree(argv);

  return command_line_arguments;
}

std::string Utf8FromUtf16(const wchar_t* utf16_string) {
  if (utf16_string == nullptr) {
    return std::string();
  }
  unsigned int target_length = ::WideCharToMultiByte(
      CP_UTF8, WC_ERR_INVALID_CHARS, utf16_string,
      -1, nullptr, 0, nullptr, nullptr)
    -1; // remove the trailing null character
  int input_length = (int)wcslen(utf16_string);
  std::string utf8_string;
  if (target_length == 0 || target_length > utf8_string.max_size()) {
    return utf8_string;
  }
  utf8_string.resize(target_length);
  int converted_length = ::WideCharToMultiByte(
      CP_UTF8, WC_ERR_INVALID_CHARS, utf16_string,
      input_length, utf8_string.data(), target_length, nullptr, nullptr);
  if (converted_length == 0) {
    return std::string();
  }
  return utf8_string;
}
