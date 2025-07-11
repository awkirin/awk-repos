
function FindProxyForURL(url, host) {
	var blacklist = [
		'*.io',
		'*.tv',
		'*.to',
		'*.su',
		'*.cfglobalcdn.com',
		'*.cloudflare.com',

		'*.openai.com',

		'*.instagram.com',
		'*.mattermost.com',
		'mattermost.com',

		'*._youtube.com',
		'*._googlevideo.com',
		'*._ytimg.com',
	];
	
	var whitelist = [

        'roots.io',
        '*.roots.io',

		'*.babia.to',
		'babia.to',

		'*.roots.io',
		'roots.io',

		'*.docker.io',
		'*.gofile.io',
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
            return "SOCKS5 localhost:9150; DIRECT";
        }
    }

    return "DIRECT";
}
