#include <windows.h>
#include <shlobj.h>
#include <shlwapi.h>
#include <algorithm>
#include <string>
#include <vector>

#pragma comment(lib, "ole32.lib")
#pragma comment(lib, "shell32.lib")
#pragma comment(lib, "shlwapi.lib")

namespace {

constexpr wchar_t kClsid[] = L"{BFD9F3B4-3C8C-4B1C-8E57-1F4BA6A96F3E}";
constexpr wchar_t kMenuTitle[] = L"Vertree";

constexpr wchar_t kCmdBackup[] = L"--backup";
constexpr wchar_t kCmdExpressBackup[] = L"--express-backup";
constexpr wchar_t kCmdMonitor[] = L"--monit";
constexpr wchar_t kCmdViewTree[] = L"--viewtree";

HINSTANCE g_instance = nullptr;
long g_module_lock = 0;

std::wstring GetModuleDir() {
  wchar_t path[MAX_PATH];
  GetModuleFileNameW(nullptr, path, MAX_PATH);
  PathRemoveFileSpecW(path);
  return std::wstring(path);
}

std::wstring GetAppPath() {
  std::wstring dir = GetModuleDir();
  return dir + L"\\vertree.exe";
}

bool LaunchAppWithArgs(const std::wstring& args) {
  std::wstring app = GetAppPath();
  SHELLEXECUTEINFOW sei = {};
  sei.cbSize = sizeof(sei);
  sei.fMask = SEE_MASK_NOCLOSEPROCESS;
  sei.lpFile = app.c_str();
  sei.lpParameters = args.c_str();
  sei.nShow = SW_SHOWNORMAL;
  if (!ShellExecuteExW(&sei)) {
    return false;
  }
  if (sei.hProcess) {
    CloseHandle(sei.hProcess);
  }
  return true;
}

std::wstring BuildArgs(const std::wstring& verb, const std::wstring& path) {
  std::wstring quoted = L"\"" + path + L"\"";
  return std::wstring(verb) + L" " + quoted;
}

std::wstring GetFirstItemPath(IShellItemArray* items) {
  if (!items) return L"";
  IShellItem* item = nullptr;
  if (FAILED(items->GetItemAt(0, &item)) || !item) {
    return L"";
  }
  wchar_t* path = nullptr;
  std::wstring result;
  if (SUCCEEDED(item->GetDisplayName(SIGDN_FILESYSPATH, &path)) && path) {
    result = path;
    CoTaskMemFree(path);
  }
  item->Release();
  return result;
}

class ComObjectBase {
 public:
  ULONG AddRef() { return InterlockedIncrement(&ref_count_); }
  ULONG Release() {
    ULONG count = InterlockedDecrement(&ref_count_);
    if (count == 0) delete this;
    return count;
  }

 protected:
  virtual ~ComObjectBase() = default;

 private:
  ULONG ref_count_ = 1;
};

class ExplorerCommand : public IExplorerCommand, public ComObjectBase {
 public:
  ExplorerCommand(const std::wstring& title, const std::wstring& verb)
      : title_(title), verb_(verb) {}

  HRESULT STDMETHODCALLTYPE QueryInterface(REFIID riid, void** ppv) override {
    if (!ppv) return E_POINTER;
    if (riid == IID_IUnknown || riid == IID_IExplorerCommand) {
      *ppv = static_cast<IExplorerCommand*>(this);
      AddRef();
      return S_OK;
    }
    *ppv = nullptr;
    return E_NOINTERFACE;
  }

  ULONG STDMETHODCALLTYPE AddRef() override { return ComObjectBase::AddRef(); }
  ULONG STDMETHODCALLTYPE Release() override { return ComObjectBase::Release(); }

  HRESULT STDMETHODCALLTYPE GetTitle(IShellItemArray*, LPWSTR* name) override {
    if (!name) return E_POINTER;
    *name = (LPWSTR)CoTaskMemAlloc(
        (title_.size() + 1) * sizeof(wchar_t));
    if (!*name) return E_OUTOFMEMORY;
    wcscpy_s(*name, title_.size() + 1, title_.c_str());
    return S_OK;
  }

  HRESULT STDMETHODCALLTYPE GetIcon(IShellItemArray*, LPWSTR* icon) override {
    if (!icon) return E_POINTER;
    *icon = nullptr;
    return S_FALSE;
  }

  HRESULT STDMETHODCALLTYPE GetToolTip(IShellItemArray*, LPWSTR* tip) override {
    if (!tip) return E_POINTER;
    *tip = nullptr;
    return S_FALSE;
  }

  HRESULT STDMETHODCALLTYPE GetCanonicalName(GUID* guid) override {
    if (!guid) return E_POINTER;
    *guid = GUID_NULL;
    return S_FALSE;
  }

  HRESULT STDMETHODCALLTYPE GetState(IShellItemArray*, BOOL, EXPCMDSTATE* state) override {
    if (!state) return E_POINTER;
    *state = ECS_ENABLED;
    return S_OK;
  }

  HRESULT STDMETHODCALLTYPE Invoke(IShellItemArray* items, IBindCtx*) override {
    std::wstring path = GetFirstItemPath(items);
    if (path.empty()) return E_FAIL;
    std::wstring args = BuildArgs(verb_, path);
    return LaunchAppWithArgs(args) ? S_OK : E_FAIL;
  }

  HRESULT STDMETHODCALLTYPE GetFlags(EXPCMDFLAGS* flags) override {
    if (!flags) return E_POINTER;
    *flags = ECF_DEFAULT;
    return S_OK;
  }

  HRESULT STDMETHODCALLTYPE EnumSubCommands(IEnumExplorerCommand** enum_commands) override {
    if (!enum_commands) return E_POINTER;
    *enum_commands = nullptr;
    return E_NOTIMPL;
  }

 private:
  std::wstring title_;
  std::wstring verb_;
};

class CommandEnumerator : public IEnumExplorerCommand, public ComObjectBase {
 public:
  CommandEnumerator() {
    commands_.push_back(new ExplorerCommand(L"Backup", kCmdBackup));
    commands_.push_back(new ExplorerCommand(L"Express Backup", kCmdExpressBackup));
    commands_.push_back(new ExplorerCommand(L"Monitor", kCmdMonitor));
    commands_.push_back(new ExplorerCommand(L"View Tree", kCmdViewTree));
  }

  ~CommandEnumerator() override {
    for (auto* cmd : commands_) {
      cmd->Release();
    }
  }

  HRESULT STDMETHODCALLTYPE QueryInterface(REFIID riid, void** ppv) override {
    if (!ppv) return E_POINTER;
    if (riid == IID_IUnknown || riid == IID_IEnumExplorerCommand) {
      *ppv = static_cast<IEnumExplorerCommand*>(this);
      AddRef();
      return S_OK;
    }
    *ppv = nullptr;
    return E_NOINTERFACE;
  }

  ULONG STDMETHODCALLTYPE AddRef() override { return ComObjectBase::AddRef(); }
  ULONG STDMETHODCALLTYPE Release() override { return ComObjectBase::Release(); }

  HRESULT STDMETHODCALLTYPE Next(ULONG celt, IExplorerCommand** out, ULONG* fetched) override {
    if (!out) return E_POINTER;
    ULONG count = 0;
    while (count < celt && index_ < commands_.size()) {
      out[count] = commands_[index_];
      out[count]->AddRef();
      index_++;
      count++;
    }
    if (fetched) *fetched = count;
    return (count == celt) ? S_OK : S_FALSE;
  }

  HRESULT STDMETHODCALLTYPE Skip(ULONG celt) override {
    index_ = std::min(index_ + celt, commands_.size());
    return (index_ >= commands_.size()) ? S_FALSE : S_OK;
  }

  HRESULT STDMETHODCALLTYPE Reset() override {
    index_ = 0;
    return S_OK;
  }

  HRESULT STDMETHODCALLTYPE Clone(IEnumExplorerCommand** out) override {
    if (!out) return E_POINTER;
    auto* clone = new CommandEnumerator();
    clone->index_ = index_;
    *out = clone;
    return S_OK;
  }

 private:
  std::vector<ExplorerCommand*> commands_;
  size_t index_ = 0;
};

class RootCommand : public IExplorerCommand, public ComObjectBase {
 public:
  HRESULT STDMETHODCALLTYPE QueryInterface(REFIID riid, void** ppv) override {
    if (!ppv) return E_POINTER;
    if (riid == IID_IUnknown || riid == IID_IExplorerCommand) {
      *ppv = static_cast<IExplorerCommand*>(this);
      AddRef();
      return S_OK;
    }
    *ppv = nullptr;
    return E_NOINTERFACE;
  }

  ULONG STDMETHODCALLTYPE AddRef() override { return ComObjectBase::AddRef(); }
  ULONG STDMETHODCALLTYPE Release() override { return ComObjectBase::Release(); }

  HRESULT STDMETHODCALLTYPE GetTitle(IShellItemArray*, LPWSTR* name) override {
    if (!name) return E_POINTER;
    *name = (LPWSTR)CoTaskMemAlloc(
        (wcslen(kMenuTitle) + 1) * sizeof(wchar_t));
    if (!*name) return E_OUTOFMEMORY;
    wcscpy_s(*name, wcslen(kMenuTitle) + 1, kMenuTitle);
    return S_OK;
  }

  HRESULT STDMETHODCALLTYPE GetIcon(IShellItemArray*, LPWSTR* icon) override {
    if (!icon) return E_POINTER;
    *icon = nullptr;
    return S_FALSE;
  }

  HRESULT STDMETHODCALLTYPE GetToolTip(IShellItemArray*, LPWSTR* tip) override {
    if (!tip) return E_POINTER;
    *tip = nullptr;
    return S_FALSE;
  }

  HRESULT STDMETHODCALLTYPE GetCanonicalName(GUID* guid) override {
    if (!guid) return E_POINTER;
    *guid = GUID_NULL;
    return S_FALSE;
  }

  HRESULT STDMETHODCALLTYPE GetState(IShellItemArray*, BOOL, EXPCMDSTATE* state) override {
    if (!state) return E_POINTER;
    *state = ECS_ENABLED;
    return S_OK;
  }

  HRESULT STDMETHODCALLTYPE Invoke(IShellItemArray*, IBindCtx*) override {
    return S_OK;
  }

  HRESULT STDMETHODCALLTYPE GetFlags(EXPCMDFLAGS* flags) override {
    if (!flags) return E_POINTER;
    *flags = ECF_HASSUBCOMMANDS;
    return S_OK;
  }

  HRESULT STDMETHODCALLTYPE EnumSubCommands(IEnumExplorerCommand** enum_commands) override {
    if (!enum_commands) return E_POINTER;
    *enum_commands = new CommandEnumerator();
    return S_OK;
  }
};

class ClassFactory : public IClassFactory, public ComObjectBase {
 public:
  HRESULT STDMETHODCALLTYPE QueryInterface(REFIID riid, void** ppv) override {
    if (!ppv) return E_POINTER;
    if (riid == IID_IUnknown || riid == IID_IClassFactory) {
      *ppv = static_cast<IClassFactory*>(this);
      AddRef();
      return S_OK;
    }
    *ppv = nullptr;
    return E_NOINTERFACE;
  }

  ULONG STDMETHODCALLTYPE AddRef() override { return ComObjectBase::AddRef(); }
  ULONG STDMETHODCALLTYPE Release() override { return ComObjectBase::Release(); }

  HRESULT STDMETHODCALLTYPE CreateInstance(IUnknown* outer, REFIID riid, void** ppv) override {
    if (outer) return CLASS_E_NOAGGREGATION;
    auto* root = new RootCommand();
    HRESULT hr = root->QueryInterface(riid, ppv);
    root->Release();
    return hr;
  }

  HRESULT STDMETHODCALLTYPE LockServer(BOOL lock) override {
    if (lock) {
      InterlockedIncrement(&g_module_lock);
    } else {
      InterlockedDecrement(&g_module_lock);
    }
    return S_OK;
  }
};

}  // namespace

int WINAPI wWinMain(HINSTANCE instance, HINSTANCE, PWSTR, int) {
  g_instance = instance;
  CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  CLSID clsid;
  HRESULT hr = CLSIDFromString(kClsid, &clsid);
  if (FAILED(hr)) {
    CoUninitialize();
    return 1;
  }

  DWORD cookie = 0;
  auto* factory = new ClassFactory();
  hr = CoRegisterClassObject(
      clsid,
      static_cast<IUnknown*>(factory),
      CLSCTX_LOCAL_SERVER,
      REGCLS_MULTIPLEUSE,
      &cookie);
  factory->Release();

  if (FAILED(hr)) {
    CoUninitialize();
    return 1;
  }

  MSG msg;
  while (GetMessageW(&msg, nullptr, 0, 0)) {
    TranslateMessage(&msg);
    DispatchMessageW(&msg);
  }

  CoRevokeClassObject(cookie);
  CoUninitialize();
  return 0;
}
