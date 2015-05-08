#!/usr/bin/env python
# -*- coding: utf-8 -*-

import glob
import logging
import os
import shutil
import sys
import time
import traceback
from PIL import Image
from utilities import get_config
from utilities import tweet
from utilities import get_random_tweet_quote
from images2gif import writeGif
from watchdog.observers import Observer
from watchdog.events import PatternMatchingEventHandler
from watchdog.events import LoggingEventHandler
import argparse


IMAGE_PATH = '/Users/ryankanno/Projects/Makerfaire/i-like-to-move-it-images/'
IMAGE_PROCESSED_PATH = '/Users/ryankanno/Projects/Makerfaire/i-like-to-move-it-images-processed/'

LOG_FORMAT = '%(asctime)s %(levelname)s %(message)s'

CONFIG = get_config('iliketomoveit.ini')


class ImageHandler(PatternMatchingEventHandler):

    patterns=["*DONE*"]

    def process(self, event):
        """
        event.event_type
            'modified' | 'created' | 'moved' | 'deleted'
        event.is_directory
            True | False
        event.src_path
            path/to/observed/file
        """
        if event.event_type == 'created':
            parent_dir = os.path.dirname(os.path.realpath(event.src_path))
            images = [Image.open(image) for image in glob.glob(parent_dir + "/*.png")]
            filename = parent_dir + "/output.gif"
            writeGif(filename, images, duration=0.2)
            with open(filename, 'rb') as gif:
                quote = get_random_tweet_quote();
                logging.info("tweeting quote: {0}".format(quote))
                tweet(CONFIG, quote, photo=gif)

            shutil.move(parent_dir + "/", IMAGE_PROCESSED_PATH)

    def on_modified(self, event):
        self.process(event)

    def on_created(self, event):
        self.process(event)


def parse_options():
    global IMAGE_PATH
    global IMAGE_PROCESSED_PATH
    parser = argparse.ArgumentParser()
    parser.add_argument("--image-path", dest="image_path", default=IMAGE_PATH)
    parser.add_argument("--processed-path", dest="image_processed_path", default=IMAGE_PROCESSED_PATH)
    opts = parser.parse_args();

    IMAGE_PATH = opts.image_path
    IMAGE_PROCESSED_PATH = opts.image_processed_path

    logging.info("IMAGE_PATH={0}".format(IMAGE_PATH));
    logging.info("IMAGE_PROCESSED_PATH={0}".format(IMAGE_PROCESSED_PATH));

def main():

    logging.basicConfig(level=logging.INFO, format=LOG_FORMAT)

    parse_options();

    try:
        observer = Observer()
        observer.schedule(ImageHandler(), IMAGE_PATH, recursive=True)
        observer.start()
        try:
            while True:
                time.sleep(1)
        except KeyboardInterrupt:
            observer.stop()
        observer.join()
    except:
        trace = traceback.format_exc()
        logging.error("OMGWTFBBQ: {0}".format(trace))
        sys.exit(1)

    # Yayyy-yah
    sys.exit(0)


if __name__ == "__main__":
    sys.exit(main())

# vim: filetype=python
