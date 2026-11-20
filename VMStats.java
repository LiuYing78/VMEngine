package com.vmengine;

public class VMStats {
    public long icount;        // 已执行指令数
    public long tbCount;       // TB 数量
    public long tlbHits;       // TLB 命中
    public long tlbMisses;     // TLB 未命中
    public long mmioCount;     // MMIO 访问次数
    public int  cpuUsage;      // CPU 占用率 %
    public long memUsedMb;     // 当前占用内存 MB
    public String uptime;      // 运行时间

    public static native VMStats nativeGetStats();
}
