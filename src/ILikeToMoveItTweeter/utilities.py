#!/usr/bin/env python
# -*- coding: utf-8 -*-

import ConfigParser
import random
from twython import Twython
from twython import TwythonError


def get_config(config_name):
    config = ConfigParser.ConfigParser()
    config.read(config_name)
    return config


def tweet(config, message, photo=None):
    consumer_key = config.get('twitter_credentials', 'consumer_key')
    consumer_secret = config.get('twitter_credentials', 'consumer_secret')
    access_token = config.get('twitter_credentials', 'access_token')
    access_token_secret = config.get('twitter_credentials', 'access_token_secret')

    twitter = Twython(consumer_key, consumer_secret, access_token, access_token_secret)

    try:
        if photo:
            twitter.update_status_with_media(status=message, media=photo)
        else:
            twitter.update_status(status=message)
    except TwythonError as e:
        pass


def get_random_tweet_quote():
    quote_format = "{0} - @hnlmakerspace #HNLMKF"
    quotes = [
        "Imagine all the people...",
        "You can't do it unless you can imagine it.",
        "There are no rules of architecture for a castle in the clouds.",
        "If you can imagine it, you can achieve it. If you can dream it, you can become it.",
        "Vision is the true creative rhythm.",
        "Imagination creates reality.",
        "Man lives by imagination.",
        "To imagine is everything, to know is nothing at all.",
        "Imagination is the eye of the soul.",
        "Ideas control the world.",
        "I imagine, therefore I belong and am free."
    ]
    quote = random.choice(quotes)
    return quote_format.format(quote)



if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))

# vim: filetype=python
