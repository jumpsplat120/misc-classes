---@type Object
local Object
local Process, fii, private

ffi = require("ffi")

Object  = require("lib.Classy")
private = require("lib.Classy.instances")

Process = Object:extend()

private[Process] = {}

    --======PRIVATE FUNCTIONS======--

local dw_flag_values = {
    force_on_feedback = 0x00000040,
    force_off_feedback = 0x00000080,
    prevent_pinning = 0x00002000,
    run_fullscreen = 0x00000020,
    title_is_appid = 0x00001000,
    title_is_link_name = 0x00000800,
    untrusted_source = 0x00008000,
    use_count_chars = 0x00000008,
    use_fill_attribute = 0x00000010,
    use_hotkey = 0x00000200,
    use_position = 0x00000004,
    use_show_window = 0x00000001,
    use_size = 0x00000002,
    use_std_handles = 0x00000100
}

local window_values = {
    hide = 0,
    normal = 1,
    shownormal = 1,
    show_normal = 1,
    showminimized = 2,
    show_minimized = 2,
    showmaximized = 3,
    show_maximized = 3,
    maximize = 3,
    maximized = 3,
    shownoactivate = 4,
    show_no_activate = 4,
    no_activate = 4,
    show = 5,
    minimize = 6,
    shownominactivate = 7,
    show_no_min_activate = 7,
    no_min_activate = 7,
    minimized_non_active = 7,
    showna = 8,
    show_na = 8,
    not_active = 8,
    non_active = 8,
    restore = 9,
    showdefault = 10,
    show_default = 10,
    default = 10,
    forceminimize = 11,
    force_minimize = 11
}

assert(ffi, "CreateProcess; missing required library - ffi")

ffi.cdef[[
typedef struct _STARTUPINFOA {
  uint32_t  cb;
  void *    lpReserved;
  void *    lpDesktop;
  void *    lpTitle;
  uint32_t  dwX;
  uint32_t  dwY;
  uint32_t  dwXSize;
  uint32_t  dwYSize;
  uint32_t  dwXCountChars;
  uint32_t  dwYCountChars;
  uint32_t  dwFillAttribute;
  uint32_t  dwFlags;
  uint16_t  wShowWindow;
  uint16_t  cbReserved2;
  void *    lpReserved2;
  void **   hStdInput;
  void **   hStdOutput;
  void **   hStdError;
} STARTUPINFOA, *LPSTARTUPINFOA;

typedef struct _PROCESS_INFORMATION {
  void **  hProcess;
  void **  hThread;
  uint32_t dwProcessId;
  uint32_t dwThreadId;
} PROCESS_INFORMATION, *LPPROCESS_INFORMATION;

uint32_t CreateProcessA(
  void *,
  const char * commandLine,
  void *,
  void *,
  uint32_t,
  uint32_t,
  void *,
  const char * currentDirectory,
  LPSTARTUPINFOA,
  LPPROCESS_INFORMATION
);

uint32_t CloseHandle(void **);

uint32_t TerminateProcess(void **);
]]

    --======CONSTRUCTOR======--

function Process:new(command)
    local p = private[self]

    p.startup_info = ffi.new("STARTUPINFOA")
    p.process_info = ffi.new("PROCESS_INFORMATION")

    p.startup_info.cb = ffi.sizeof(p.startup_info)
    
    p.dw_flags = {
        force_on_feedback = false,
        force_off_feedback = false,
        prevent_pinning = false,
        run_fullscreen = false,
        title_is_appid = false,
        title_is_link_name = false,
        untrusted_source = false,
        use_count_chars = false,
        use_fill_attribute = false,
        use_hotkey = false,
        use_position = false,
        use_show_window = false,
        use_size = false,
        use_std_handles = true
    }

    p.startup_info.hStdOutput = io.stdout
    p.startup_info.hStdInput  = io.stdin
    p.startup_info.hStdError  = io.stderr

    p.calling_directory = ""
    p.show_window       = "default"

    self.command = command
end

    --======STATIC======--

    --======METHODS======--

function Process:execute()
    local p, dir, status_code

    p = private[self]

    if p.calling_directory ~= "" then dir = p.calling_directory end

    for key, value in pairs(p.dw_flags) do
        if value then p.startup_info.dwFlags = p.startup_info.dwFlags + dw_flag_values[key] end
    end

    if p.dw_flags.use_show_window then
        p.startup_info.wShowWindow = window_values[p.show_window:lower()]
    end

    status_code = ffi.C.CreateProcessA(nil, self.command, nil, nil, 0, 0, nil, dir, p.startup_info, p.process_info)

    return p.process_info, status_code
end

function Process:close()
    local p = private[self]

    ffi.C.TerminateProcess(p.process_info.hProcess)
    
    ffi.C.CloseHandle(p.process_info.hProcess)
    ffi.C.CloseHandle(p.process_info.hThread)
end

    --======GETTERS======--

function Process.__get:use_show_window()
    return private[self].dw_flags.use_show_window
end

function Process.__get:show_window()
    return private[self].show_window
end

    --======SETTERS======--

function Process.__set:use_show_window(value)
    private[self].dw_flags.use_show_window = value
end

function Process.__set:show_window(value)
    private[self].show_window = value
end

    --======METAMETHODS======--

function Process:__tostring()
    if self.is_instance then
        return self:tostringHelper()
    else
        return self:tostringHelper("Class")
    end
end

Process.__type = "Process"

return Process