{ prev, ... }:
# Override the unwrapped build but keep the wrapper: it puts yt-dlp on mpv's
# PATH and accepts `scripts`, which home-manager's programs.mpv.scripts uses.
prev.mpv.override {
  mpv-unwrapped = prev.mpv-unwrapped.override {
    ffmpeg = prev.ffmpeg_6-full;
  };
}
