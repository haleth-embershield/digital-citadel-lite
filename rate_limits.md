  [dns.rateLimit]
    # Rate-limited queries are answered with a REFUSED reply and not further processed by
    # FTL.
    # The default settings for FTL's rate-limiting are to permit no more than 1000 queries
    # in 60 seconds. Both numbers can be customized independently. It is important to note
    # that rate-limiting is happening on a per-client basis. Other clients can continue to
    # use FTL while rate-limited clients are short-circuited at the same time.
    # For this setting, both numbers, the maximum number of queries within a given time,
    # and the length of the time interval (seconds) have to be specified. For instance, if
    # you want to set a rate limit of 1 query per hour, the option should look like
    # RATE_LIMIT=1/3600. The time interval is relative to when FTL has finished starting
    # (start of the daemon + possible delay by DELAY_STARTUP) then it will advance in
    # steps of the rate-limiting interval. If a client reaches the maximum number of
    # queries it will be blocked until the end of the current interval. This will be
    # logged to /var/log/pihole/FTL.log, e.g. Rate-limiting 10.0.1.39 for at least 44
    # seconds. If the client continues to send queries while being blocked already and
    # this number of queries during the blocking exceeds the limit the client will
    # continue to be blocked until the end of the next interval (FTL.log will contain
    # lines like Still rate-limiting 10.0.1.39 as it made additional 5007 queries). As
    # soon as the client requests less than the set limit, it will be unblocked (Ending
    # rate-limitation of 10.0.1.39).
    # Rate-limiting may be disabled altogether by setting both values to zero (this
    # results in the same behavior as before FTL v5.7).
    # How many queries are permitted...
    count = 1000

    # ... in the set interval before rate-limiting?
    interval = 60