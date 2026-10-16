import android.media.AudioFormat;
import android.media.AudioRecord;
import android.media.AudioTrack;
import android.media.MediaRecorder;
import android.media.AudioManager;

public class AudioLoop {
    public static void main(String[] args) {
        int sampleRate = 48000;
        int channelIn = AudioFormat.CHANNEL_IN_STEREO;
        int channelOut = AudioFormat.CHANNEL_OUT_STEREO;
        int encoding = AudioFormat.ENCODING_PCM_16BIT;

        int minRecBuf = AudioRecord.getMinBufferSize(sampleRate, channelIn, encoding);
        int minTrackBuf = AudioTrack.getMinBufferSize(sampleRate, channelOut, encoding);
        int bufferSize = Math.max(minRecBuf, minTrackBuf) * 2;

        AudioRecord recorder = new AudioRecord(
            MediaRecorder.AudioSource.UNPROCESSED,
            sampleRate, channelIn, encoding, bufferSize
        );

        AudioTrack tracker = new AudioTrack(
            AudioManager.STREAM_MUSIC,
            sampleRate, channelOut, encoding, bufferSize,
            AudioTrack.MODE_STREAM
        );

        byte[] buffer = new byte[bufferSize];
        recorder.startRecording();
        tracker.play();
        System.out.println("AUDIO_LOOP_STARTED");

        while (!Thread.interrupted()) {
            int read = recorder.read(buffer, 0, buffer.length);
            if (read > 0) {
                tracker.write(buffer, 0, read);
            }
        }
    }
}