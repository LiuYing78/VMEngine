package com.vmengine;

import android.view.Surface;
import android.view.TextureView;

public class VMConfig {
    public int cpuCores = 4;
    public int memoryMb = 2048;
    public String kernelPath = "";
    public String initrdPath = "";
    public String diskPath = "";
    public String cmdline = "console=ttyAMA0 root=/dev/vda rw";
    public TextureView renderSurface;
    public int displayWidth = 1280;
    public int displayHeight = 720;

    public boolean isValid() {
        return cpuCores > 0 && cpuCores <= 8 && memoryMb > 0 && kernelPath != null && !kernelPath.isEmpty();
    }
}
