#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include "flutter_window.h"
#include "utils.h"

BOOL isRunAsAdmin();
void runAsAdmin();
BOOL isAlreadyRunning();

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {

    BOOL alreadyRunning = isAlreadyRunning();
    BOOL isAdmin = isRunAsAdmin();

  if (!isAdmin) {
     runAsAdmin();
     return 0;  // 避免 `exit(0);` 影响 `flutter run`
  }
  if(alreadyRunning){

  }

  // 初始化 COM，确保插件正常运行
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  // 处理控制台连接
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  if (!window.Create(L"vertree", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  // 处理 Windows 消息循环
  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}

BOOL isAlreadyRunning() {
    HANDLE hMutex = CreateMutex(NULL, TRUE, L"w0fv1.dev.vertree");
    if (GetLastError() == ERROR_ALREADY_EXISTS) {
        CloseHandle(hMutex);
        return TRUE;
    }
    (void)hMutex; // Suppress unused variable warning
    return FALSE;
}



BOOL isRunAsAdmin() {
    BOOL isAdmin = FALSE;
    HANDLE hToken = NULL;
    if (OpenProcessToken(GetCurrentProcess(), TOKEN_QUERY, &hToken)) {
        TOKEN_ELEVATION elevation;
        DWORD dwSize = 0;
        if (GetTokenInformation(hToken, TokenElevation, &elevation, sizeof(elevation), &dwSize)) {
            isAdmin = elevation.TokenIsElevated;
        }
        CloseHandle(hToken);
    }
    return isAdmin;
}

void runAsAdmin() {
    WCHAR filePath[MAX_PATH];
    GetModuleFileName(NULL, filePath, MAX_PATH);

    // 获取命令行参数
    LPWSTR commandLine = GetCommandLine();

    SHELLEXECUTEINFO sei = { sizeof(sei) };
    sei.lpVerb = L"runas";  // 以管理员权限运行
    sei.lpFile = filePath;
    sei.lpParameters = commandLine; // 传递参数
    sei.nShow = SW_SHOW;
    sei.fMask = SEE_MASK_NOCLOSEPROCESS;

    if (ShellExecuteEx(&sei)) {
        // 等待管理员进程启动
        if (sei.hProcess) {
            WaitForSingleObject(sei.hProcess, INFINITE);
            CloseHandle(sei.hProcess);
        }
        exit(0);  // 退出当前进程，防止重复运行
    } else {
        MessageBox(NULL, L"需要管理员权限才能运行此应用！", L"权限错误", MB_OK | MB_ICONERROR);
    }
}
