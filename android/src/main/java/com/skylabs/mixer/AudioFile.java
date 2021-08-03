package com.skylabs.mixer;
import android.content.ContentUris;
import android.content.Context;
import android.content.res.AssetFileDescriptor;
import android.database.Cursor;
import android.media.AudioAttributes;
import android.media.MediaPlayer;
import android.media.audiofx.DynamicsProcessing;
import android.media.audiofx.Visualizer;
import android.net.Uri;
import android.os.Build;
import android.os.Environment;
import android.os.ParcelFileDescriptor;
import android.os.StrictMode;
import android.provider.DocumentsContract;
import android.provider.MediaStore;
import android.util.Log;
import android.media.audiofx.DynamicsProcessing.Eq;
import android.media.audiofx.DynamicsProcessing.EqBand;


import com.getcapacitor.JSObject;

import java.io.File;
import java.net.URI;
import java.net.URLEncoder;
import java.util.HashMap;
import java.util.Map;

import static com.skylabs.mixer.Utils.getPath;

public class AudioFile implements MediaPlayer.OnPreparedListener, MediaPlayer.OnCompletionListener {
    Mixer _parent;
    private MediaPlayer player;
    private Eq eq;
    private DynamicsProcessing dp;
    private float currentVolume;
    private Visualizer visualizer;
    public String elapsedTimeEventName = "";
    public String listenerName = "";
    public boolean visualizerState = true;
    private Visualizer.MeasurementPeakRms measurementPeakRms;


    public AudioFile(Mixer parent) {
        _parent = parent;
        player = new MediaPlayer();
        player.setOnCompletionListener(this);
        player.setOnPreparedListener(this);
    }

    public void setupAudio(String audioFilePath, ChannelSettings channelSettings) {
        try {
            Uri uri = Uri.parse(audioFilePath);
            String filePath = getPath(_parent._context, uri);
            File file = new File(filePath);
            ParcelFileDescriptor pfd = ParcelFileDescriptor.open(file, ParcelFileDescriptor.MODE_READ_ONLY);
            AssetFileDescriptor afd = new AssetFileDescriptor(pfd, 0, -1);
            player.setAudioAttributes(new AudioAttributes.Builder()
                            .setUsage(AudioAttributes.USAGE_MEDIA)
                            .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                            .build()
            );
            player.setDataSource(afd.getFileDescriptor(), afd.getStartOffset(), afd.getLength());
            player.prepare();
            setupEq(channelSettings);
        }
        catch(Exception ex) {
            Log.e("setupAudio", "Exception thrown in setupAudio: " + ex);
        }
    }

    private void setupEq(ChannelSettings channelSettings) {
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.P) {
            EqBand bassEq = new EqBand(true, (float)channelSettings.eqSettings.bassFrequency, (float)channelSettings.eqSettings.bassGain);
            EqBand midEq = new EqBand(true, (float)channelSettings.eqSettings.midFrequency, (float)channelSettings.eqSettings.midGain);
            EqBand trebleEq = new EqBand(true, (float)channelSettings.eqSettings.trebleFrequency, (float)channelSettings.eqSettings.trebleGain);
            eq = new Eq(true, true, 3);
            eq.setBand(0, bassEq);
            eq.setBand(1, midEq);
            eq.setBand(2, trebleEq);
            DynamicsProcessing.Config config = new DynamicsProcessing.Config.Builder(
                    DynamicsProcessing.VARIANT_FAVOR_FREQUENCY_RESOLUTION,
                    1,
                    false, 0,
                    false, 0,
                    true, 3,
                    false
            ).setPreferredFrameDuration(10).build();
            dp = new DynamicsProcessing(0, player.getAudioSessionId(), config);
            dp.setPostEqAllChannelsTo(eq);
        }
        configureEngine(channelSettings);
    }

    private void configureEngine(ChannelSettings channelSettings) {
        if (!channelSettings.channelListenerName.isEmpty()) {
            listenerName = channelSettings.channelListenerName;
        }
        dp.setEnabled(true);
        currentVolume = (float)channelSettings.volume;
        player.setVolume(currentVolume, currentVolume);
    }

    public void setElapsedTimeEvent(String eventName) {
        elapsedTimeEventName = eventName;
    }

    public String playOrPause() {
        if (player.isPlaying()) {
            player.pause();
            destroyVisualizerListener();
            return "pause";
        } else {
            player.start();
            initVisualizerListener();
            return "play";
        }
    }

    public String stop() {
        if (player.isPlaying()) {
            player.pause();
        }
        player.seekTo(0);
        destroyVisualizerListener();
        return "stop";
    }

    public boolean isPlaying() {
        return player.isPlaying();
    }

    public void adjustVolume(double volume) {
        currentVolume = (float)volume;
        player.setVolume(currentVolume, currentVolume);
        // TODO: ? get values as floats?
    }

    public double getCurrentVolume() {
        return currentVolume;
    }

    public void adjustEq(String type, double gain, double freq) {

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            if (eq.getBandCount() < 1) {
                return;
            }
            if (type.equals("bass")) {
                EqBand bassEq = eq.getBand(0);
                bassEq.setGain((float) gain);
                bassEq.setCutoffFrequency((float) freq);
                eq.setBand(0, bassEq);
                dp.setPostEqAllChannelsTo(eq);
            }
            else if (type.equals("mid")) {
                EqBand midEq = eq.getBand(1);
                midEq.setGain((float) gain);
                midEq.setCutoffFrequency((float) freq);
                eq.setBand(1, midEq);
                dp.setPostEqAllChannelsTo(eq);
            }
            else if (type.equals("treble")) {
                EqBand trebleEq = eq.getBand(2);
                trebleEq.setGain((float) gain);
                trebleEq.setCutoffFrequency((float) freq);
                eq.setBand(2, trebleEq);
                dp.setPostEqAllChannelsTo(eq);
            }
            else {
                System.out.println("adjustEq: invalid eq type");
            }
        }
    }

    public Map<String, Object> getCurrentEq() {
        Map<String, Object> currentEq = new HashMap<String, Object>();
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.P) {
            currentEq.put("bassGain", eq.getBand(0).getGain());
            currentEq.put("bassFreq", eq.getBand(0).getCutoffFrequency());
            currentEq.put("midGain", eq.getBand(1).getGain());
            currentEq.put("midFreq", eq.getBand(1).getCutoffFrequency());
            currentEq.put("trebleGain", eq.getBand(2).getGain());
            currentEq.put("trebleFreq", eq.getBand(2).getCutoffFrequency());
        }
        return currentEq;
    }

    public Map<String, Object> getElapsedTime() {
        // Is there an event I can subscribe to?
        Map<String, Object> elapsedTime = Utils.timeToDictionary(player.getCurrentPosition());
        return elapsedTime;
    }

    public Map<String, Object> getTotalTime() {
        Map<String, Object> totalTime = Utils.timeToDictionary(player.getDuration());
        return totalTime;
    }

    public Map<String, Object> destroy() {
        stop();
        player.stop();
        player.release();
        dp.release();
        Map<String, Object> response = new HashMap<String, Object>();
        response.put("listenerName", listenerName);
        response.put("elapsedTimeEventName", elapsedTimeEventName);
        return response;
    }

    @Override
    public void onCompletion(MediaPlayer mediaPlayer) {
        try {
            stop();
        }
        catch (Exception ex) {
            Log.e("onCompletion AudioFile", "An error occurred in onCompletion. Exception: " + ex.getLocalizedMessage());
        }
    }

    @Override
    public void onPrepared(MediaPlayer mediaPlayer) {
        try {
            player.seekTo(0);
        }
        catch (Exception ex) {
            Log.e("onPrepared AudioFile", "An error occurred in onPrepared. Exception: " + ex.getLocalizedMessage());
        }
    }

    //TODO: Destroying and releasing objects
    private void initVisualizerListener() {
        visualizer = new Visualizer(player.getAudioSessionId());
        visualizer.setScalingMode(Visualizer.SCALING_MODE_AS_PLAYED);
        visualizer.setMeasurementMode(Visualizer.MEASUREMENT_MODE_PEAK_RMS);
        visualizer.setCaptureSize(Visualizer.getCaptureSizeRange()[0]);
        measurementPeakRms = new Visualizer.MeasurementPeakRms();
        visualizer.setDataCaptureListener(new Visualizer.OnDataCaptureListener() {
            @Override
            public void onWaveFormDataCapture(Visualizer vis, byte[] bytes, int i) {
                visualizer.getMeasurementPeakRms(measurementPeakRms);
                double measurement = (double)measurementPeakRms.mRms;
                measurement = (measurement / 100) * (1 / currentVolume);
                double response = measurement < -80 ? -80 : measurement;
                JSObject data = new JSObject();
                data.put("meterLevel", response);
                _parent.notifyPluginListeners(listenerName, data);

                if (!elapsedTimeEventName.isEmpty()) {
                    _parent.notifyPluginListeners(elapsedTimeEventName, Utils.buildResponseData(getElapsedTime()));
                }
            }

            @Override
            public void onFftDataCapture(Visualizer visualizer, byte[] bytes, int i) {
                Log.i("FFT Byte Array: ", String.valueOf(bytes[0]));
            }
        }, Visualizer.getMaxCaptureRate(), true, false);
        visualizer.setEnabled(true);
    }

    private void destroyVisualizerListener() {
        if (visualizer != null && visualizer.getEnabled()) {
            visualizer.setDataCaptureListener(null, 0, false, false);
            visualizer.setEnabled(false);
            visualizer.release();
        }
        return;
    }
}