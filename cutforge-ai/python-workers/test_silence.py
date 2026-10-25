import tempfile
import unittest
from pathlib import Path
from silence import scan
import subprocess

class TestSilence(unittest.TestCase):
    def test_three_second_video(self):
        with tempfile.TemporaryDirectory() as tmp:
            vid=Path(tmp)/"demo.mp4"
            subprocess.run(["ffmpeg","-v","error","-y","-f","lavfi","-i",
                            "color=c=purple:s=160x90:r=15:d=3","-f","lavfi","-i",
                            "sine=frequency=550:duration=1","-filter_complex","[1:a]apad=pad_dur=2[a]",
                            "-map","0:v","-map","[a]","-c:v","libx264","-c:a","aac","-t","3",str(vid)],
                           check=True)
            gaps=scan(str(vid),-28,.4,3)
            self.assertTrue(any(g["start"]>.7 and g["end"]>2.8 for g in gaps))

if __name__=="__main__":
    unittest.main()
