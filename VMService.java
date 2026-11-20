package com.vmengine;

import android.app.Service;
import android.content.Intent;
import android.os.IBinder;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;

public class VMService extends Service {
    private static final String TAG = "VMEngine-VMService";
    private static final int MSG_UPDATE_STATS = 1;

    private Handler mHandler;
    private boolean mRunning = false;

    static {
        System.loadLibrary("vmengine");
    }

    public static native int nativeInitVM(int cores, int ramMb);
    public static native int nativeLoadKernel(String kernelPath);
    public static native int nativeLoadInitrd(String initrdPath);
    public static native int nativeStartVM();
    public static native int nativeStopVM();
    public static native void nativeWaitVM();
    public static native long[] nativeGetStats();
    public static native int nativeGenerateART(String framework, String cache);

    public interface VMCallback {
        void onLog(String line);
        void onStats(long icount, long tbCount, long netRx, long netTx, long netBytes);
        void onStateChanged(boolean running);
    }

    private static VMCallback sCallback;

    public static void setCallback(VMCallback cb) {
        sCallback = cb;
    }

    @Override
    public void onCreate() {
        super.onCreate();
        mHandler = new Handler(Looper.getMainLooper());
        Log.i(TAG, "VMService created");
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        if (intent != null && "start".equals(intent.getAction())) {
            int cores = intent.getIntExtra("cores", 4);
            int ram = intent.getIntExtra("ram", 2048);
            String kernel = intent.getStringExtra("kernel");
            new Thread(() -> startVM(cores, ram, kernel), "vm-worker").start();
        } else if (intent != null && "stop".equals(intent.getAction())) {
            nativeStopVM();
        }
        return START_NOT_STICKY;
    }

    private void startVM(int cores, int ram, String kernel) {
        Log.i(TAG, "Starting VM: " + cores + " cores, " + ram + "MB");
        int ret = nativeInitVM(cores, ram);
        if (ret != 0) {
            Log.e(TAG, "init failed: " + ret);
            notifyState(false);
            return;
        }
        if (kernel != null) {
            ret = nativeLoadKernel(kernel);
            if (ret != 0) Log.w(TAG, "kernel load failed: " + ret);
        }
        ret = nativeStartVM();
        if (ret == 0) {
            mRunning = true;
            notifyState(true);
            startStatsLoop();
            nativeWaitVM();
            mRunning = false;
            notifyState(false);
        }
    }

    private void startStatsLoop() {
        mHandler.postDelayed(new Runnable() {
            @Override
            public void run() {
                if (!mRunning) return;
                try {
                    long[] s = nativeGetStats();
                    if (s != null && s.length >= 5 && sCallback != null) {
                        sCallback.onStats(s[0], s[1], s[2], s[3], s[4]);
                    }
                } catch (Throwable t) {
                    Log.w(TAG, "stats error", t);
                }
                mHandler.postDelayed(this, 1000);
            }
        }, 1000);
    }

    private void notifyState(final boolean running) {
        if (sCallback != null) {
            mHandler.post(() -> sCallback.onStateChanged(running));
        }
    }

    @Override
    public IBinder onBind(Intent intent) {
        return null;
    }

    @Override
    public void onDestroy() {
        nativeStopVM();
        super.onDestroy();
    }
}
