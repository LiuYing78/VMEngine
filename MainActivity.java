package com.vmengine;

import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;
import android.os.Environment;
import android.util.Log;
import android.view.SurfaceView;
import android.view.TextureView;
import android.widget.Button;
import android.widget.EditText;
import android.widget.TextView;
import android.widget.Toast;

import java.io.File;

public class MainActivity extends Activity {
    private static final String TAG = "VMEngine-Main";
    private static final int REQ_KERNEL = 1;

    private EditText mKernelPath;
    private EditText mCores;
    private EditText mRam;
    private TextView mStatus;
    private TextView mStats;
    private TextureView mScreen;
    private Button mStart, mStop;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        mKernelPath = findViewById(R.id.et_kernel);
        mCores = findViewById(R.id.et_cores);
        mRam = findViewById(R.id.et_ram);
        mStatus = findViewById(R.id.tv_status);
        mStats = findViewById(R.id.tv_stats);
        mScreen = findViewById(R.id.tv_screen);
        mStart = findViewById(R.id.btn_start);
        mStop = findViewById(R.id.btn_stop);

        String def = new File(getExternalFilesDir(null), "Image").getAbsolutePath();
        mKernelPath.setText(def);
        mCores.setText("4");
        mRam.setText("2048");

        mStart.setOnClickListener(v -> startVM());
        mStop.setOnClickListener(v -> stopVM());

        VMService.setCallback(new VMService.VMCallback() {
            @Override public void onLog(String line) { Log.i(TAG, line); }
            @Override
            public void onStats(final long icount, final long tb, final long rx,
                               final long tx, final long bytes) {
                runOnUiThread(() -> mStats.setText(
                    String.format("insn=%d tb=%d net_rx=%d net_tx=%d bytes=%d",
                                  icount, tb, rx, tx, bytes)));
            }
            @Override public void onStateChanged(final boolean running) {
                runOnUiThread(() -> mStatus.setText(running ? "Running" : "Stopped"));
            }
        });
    }

    private void startVM() {
        Intent i = new Intent(this, VMService.class);
        i.setAction("start");
        i.putExtra("cores", Integer.parseInt(mCores.getText().toString()));
        i.putExtra("ram", Integer.parseInt(mRam.getText().toString()));
        i.putExtra("kernel", mKernelPath.getText().toString());
        startService(i);
        Toast.makeText(this, "Starting VM...", Toast.LENGTH_SHORT).show();
    }

    private void stopVM() {
        Intent i = new Intent(this, VMService.class);
        i.setAction("stop");
        startService(i);
    }
}
