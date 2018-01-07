
@call mingwpath -quiet
@echo Building res.rc (interfaces)...

:: Before I only used one version for both 64 and 32 bit (whatever the default output is, pe-x86-64
:: I think), but once I started using cgo that no longer worked. AFAICT the only difference in the
:: output is the header, so it's probably just the C linker being less flexible than the Go linker.

:: I do remember reading something about the Go linker being able to link in just about any object
:: format, not just the "correct" one for a certain system...

:: Anyway, it worked before with only one format, and it works now with two. As long as it works somehow
:: I don't care.

@cd universal
@windres -F pe-i386 -o res_windows_386.syso ./res.rc
@windres -F pe-x86-64 -o res_windows_amd64.syso ./res.rc
