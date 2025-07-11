function FindProxyForURL(url, host) {
    var blacklist = [
        '*.google.com',
        '*.openai.com',
        '*.cloudflare.com',
        '*.xreal.com',
        '*.synology.com',
        '*.vpnbook.com',
        '*.medium.com',
        '*.suno.com',
        '*.mailgun.com',
        '*.heroku.com',
        '*.lantern.io',
        '*.patreon.com',
        '*.chatgpt.com',
        '*.hashicorp.com',
        '*.vagrantcloud.com',
        '*.amazonaws.com',
        '*.facebook.com',
        '*.instagram.com',

        '*.jetbra.in',
        '*.jetbrains.com',

        '*.youtube.com',
        '*.ggpht.com',
        '*.ytimg.com',
		'*.googlevideo.com',

        '*.torproject.org',
        '*.io',
        '*.tv',
        '*.to',
		'*.su',
    ];

    var whitelist = [
        'accounts.google.com',
	    'dl.google.com',
	    'docs.google.com',
	    'drive.google.com',
	    'mail.google.com',
	    'translate.googleapis.com',
	    'www.google.com',
        'maps.google.com',
    ];



    if (!host) return "DIRECT";

    if (host === "localhost" || isPlainHostName(host)) {
        return "DIRECT";
    }

    if (isPlainHostName(host)) {
        return "DIRECT";
    }

    var hostOnly = host.split(':')[0].toLowerCase();


    for (var i = 0; i < whitelist.length; i++) {
        if (shExpMatch(hostOnly, whitelist[i])) {
            return "DIRECT";
        }
    }


    for (var i = 0; i < blacklist.length; i++) {
        if (shExpMatch(hostOnly, blacklist[i])) {
            return "SOCKS5 localhost:9050; SOCKS5 localhost:9150; DIRECT";
        }
    }

    return "DIRECT";
}
