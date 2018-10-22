<?php
/**
 * phpinfo() in a pretty view
 * 
 * @author      SynCap < syncap@ya.ru >
 * @copyright	(c)2009,2013,2015 Constantin Loskutov, www.syncap.ru
 *
 */

define('PPI_VERSION', '2016-35');
define('PPI_GITHUB_SOURCE_PATH', 'https://raw.githubusercontent.com/SynCap/PHP-Info/master/info.php');

if (isset($_GET['format']) && $_GET['format'] == 'json') {
	header('Content-type: application/json');
	echo json_encode(['version' => PHP_VERSION] + ini_get_all(NULL, FALSE));
	die();
}

/*

  Very old school mini router for some additional commands

  native - launch native phpinfo($mode) with `mode` as another GET param
  update - get fresh version from GitHub and launch it

*/
if (isset($_GET['do'])) {

	switch ($_GET['do']) {
		case 'native':
			/*
				If we need, we can call native phpinfo(). In this case we don't need any other porcessings.
				Just do it, then die. ;)

				INFO_GENERAL        1
				INFO_CREDITS        2
				INFO_CONFIGURATION  4
				INFO_MODULES        8
				INFO_ENVIRONMENT   16
				INFO_VARIABLES     32
				INFO_LICENSE       64
				INFO_ALL           -1

				if requested mode is NOT integer in range of INFO_GENERAL..INFO_LICENSE, 
				for example some textual or non-legal integer, we assume default value INFO_ALL
			*/
			$mode = 0+$_GET['mode'] & 64 > 0 
				?$_GET['mode'] 
				: -1 ;
			phpinfo($mode);
			die();
			break;
		
		case 'update':
			$remoteSource = @file_get_contents(PPI_GITHUB_SOURCE_PATH);
			if (
					($remoteSource !== FALSE)
					&&
					(file_put_contents(__FILE__, $remoteSource ) !== FALSE)
				) {
				header('Location: '.$_SERVER["SCRIPT_NAME"]);
				exit('Starting with updated version');
			}
			;
			break;
	}

}

class prettyPhpInfo
{
	public $nav = "";
	public $content = "";
	public $info_arr = array();

	const FILTER_FORM = <<<'FLTF'
<form action="" class="filterForm">
	<input type="text" id="filterText">
	<input type="reset" class="btn" value="&#10060;">
</form>
FLTF;

	/**
	 * Grep the all info from built-in PHP function
	 */
	protected function phpinfo_array() {
		ob_start();
		phpinfo(INFO_GENERAL);
		phpinfo(INFO_CONFIGURATION);
		phpinfo(INFO_ENVIRONMENT);
		phpinfo(INFO_VARIABLES);
		phpinfo(INFO_MODULES);
		$info_lines = explode("\n", strip_tags(ob_get_clean(), "<tr><td><h2>"));
		$cat = "General";
		foreach($info_lines as $line) {
			// new cat?
			preg_match("~<h2>(.*)</h2>~", $line, $title) ? $cat = $title[1] : null;
			if
				(
					preg_match("~<tr><td[^>]+>([^<]*)</td><td[^>]+>([^<]*)</td></tr>~", $line, $val)
					OR
					preg_match("~<tr><td[^>]+>([^<]*)</td><td[^>]+>([^<]*)</td><td[^>]+>([^<]*)</td></tr>~", $line, $val)
				)
					$info_arr[$cat][$val[1]] = str_replace(';','; ', $val[2]);// 2016: the same made in JS, but better: on non Windows servers replaced `:` but not `;`
		}
        return $info_arr;
	}

	function __construct() {
		$this->info_arr = $this->phpinfo_array();
		foreach( $this->info_arr as $cat=>$vals ) {
			$catID = str_replace(' ', '_', $cat);
			// add navigation pane item
			$this->nav .= "<li><a href=\"#$catID\">$cat</a></li>";
			// add a section to main page
			// Q: Why not use original tables?
			// A: Because we need an our own structure, IDs and classes. 
			//    We need an ability to show exact section on startup, we need a headers separated from tables, and so on...
			$this->content .= "<section id=\"$catID\" class=\"phpinfo-section\">\n<h2>$cat <a class=\"mark\" href=\"#$catID\">#</a></h2>\n<table>\n<tbody>\n";
			foreach($vals as $key=>$val) {
				$this->content .= "<tr><td>$key</td><td>$val</td>\n";
			}
			$this->content .= "</tbody>\n</table>\n</section>\n";
		}
		$this->nav = "<div class=\"phpinfo-nav\">\n".$this::FILTER_FORM."\n<ul>\n$this->nav\n</ul></div>\n";
		return $this;
	}
}

$phpinfo = new prettyPhpInfo();
?><!DOCTYPE html>
<html>
<head>
<meta charset="utf-8"/>
<meta http-equiv="X-UA-Compatible" content="IE=Edge" />
<title>PHP info :: <?php echo  $_SERVER['HTTP_HOST'].' – '.PHP_VERSION ?></title>
<link rel="shortcut icon" id="docIcon" type="image/png">
<!-- <link rel="stylesheet" href="css/info.css"> -->
<style>body{background-color:#fff;color:#555;font-family:Calibri,Tahoma,sans-serif;font-size:14px;margin:0 auto 33%;max-width:950px}article{margin-left:180px;max-width:770px}h1{color:#379}header{background:#fff;border-radius:0 0 13px 13px;box-shadow:0 0 15px #777;padding:0 1em .5em 170px;position:fixed;top:0;width:790px;z-index:1}header h1{margin:0 2em 0 -1.6em;display:inline-block}header .topmenu{display:inline-block;margin:0;padding:0}header .topmenu #gold,header .topmenu a{color:#379;cursor:pointer;text-decoration:underline;text-decoration-line:dashed;font-style:normal;font-weight:100}header .topmenu li{display:inline-block;margin-right:1em}header .topmenu select{padding:.15em;margin:0;color:#379;border:1px solid;border-color:rgba(68,136,255,.1)}header .topmenu .btn{margin:0;width:1.5em;height:1.5em}nav#toc{bottom:0;font-size:13px;position:fixed;top:0;z-index:2}.php-logo{background:url(data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAGAAAABgCAMAAADVRocKAAAAA3NCSVQICAjb4U/gAAAAwFBMVEX///8ydpn///8ha5Eob5QvdJYpcZQ0eJqtx9bI2+T5/PxLhaU6e5y70d2vytf1+Pq+1d/////t8vZ6pb34+vzv9ffe6O5wn7fv9ffY5ezO3uaErcJgla9bkq1Eg6Lg6/DG2eOcvs6StsjG1+Clw9GMs8VXj6vW4+l1o7pNiaZBgaDT4ehmmbM/f5/e6O7///+2z9yhwNCXusuBq8BSjKjm7/Lg6/Do8PT1+Pq0zdlyobhrnLRUjaobZ43I2+Tm7/IvvDXAAAAAQHRSTlMA/////////////////////+7///////+q////////////////////////////Zt3///////93mbv//////zOI6S3sBQAAAAlwSFlzAAAOnAAADpwBB5RT3QAAABx0RVh0U29mdHdhcmUAQWRvYmUgRmlyZXdvcmtzIENTNui8sowAAAajSURBVGiB7VlXY6pKED5sQ2mCYu81ltg1mqL+/391lt0BAdEYT+7TdV4iMDvfTp/d/PnzpCc96UlPOtOR0wzI+/2bkmen0n7uoAg5833pNPtnnONst+eStXwzbfXa/VzxtVb7/Fj32z0r3cxrHGe/mz0KwoXPueyy2SkODJVhTgTI+80UY1DsmGWOMn8A5DgrOUh7WX7oCpfLqJJAlHEkRR/2OIhT+hHG8TRHbqs6opgkig4TR6GjastF89O9EMcSQpNqg3Ar3EkMk0b1BaHSPRDHPXKtGsXfbj1mL0xr7y7afwfBd+8udUwShUhPY6YmYxCs99xvtHhzUEq/ahr2aaVSKWt91XQM6ynkvN2yTqV+w/LYFDnWxlc5OES9ctVOM0fr02TjABUEwOtNHkI7yJklyT+hwuCma6muefIzjZv+VxU8KKDTpfwSstWbW1NIUShQ/ja+iNFFpUv5KXYtPIDwSgBYt7fhKcGYFUfYoRShQr5KcYRI4HRiC4Dhwf9AfXmxFVShJIV2kfBEC78osE0qRL3VcAOOp8ZWANg9+SFXV7HYEyta4RWdok4IJSYKhesRvVAK9sGdaOFHWiXHvI/sK/YBNdtTz6rYjr3P2DVClDI6R+vcHRHf/mQRl4OQqXIEkrv80NSZQpXm5Yc2wRttHiQA6odyp3DJjmzuCNxL+kAUJqM3RiuCOwjS4egUlCD0fHbbbFXKzazPn8MKq4hfE9O27daLK9/npxSiN7+wW5NCM++v+CJK0zmCAjkcBCiwNxlh3PLTUUeyVxidyrUbzDzSJ+Ipo1OI3sVBrBh/WXLFEuM1qLDPGufcAXZT2oyyQ0rub4zr4scWeA85eE9JS/wCK1NCXuSWKJvm9zKE3kMeIF3xueO/wkO5If1QFX+7kGZYAhSC6PUrlAq+KvCEMkUgcQudczPOrpAP8azpB6m6X0rxUjy+E4jec4UiS4BWwEZvqH4GYJsYO+6LF1mDSc2LwAsu72NQ5SWwMpFFPc0UUhPJduJ2PLsgzg49oEIaGaHJSFYOOpUBViNgkdTZzDItepiX34xXVU/bUI0DzQN2akhBq8Orr7hUoO77GFRZ+yuI/OKpyhcLgHAQAXsV+x6TrkWbQ0cGo+9j+X5C/egd+DURv8toU3nJG+cFgLYJCqaveR0MgUd5kAuW9VMeW2AHbmfpI7lJdpB5JBjZQDSeGfoMnAyab6kYE5XpcAs+J2ozEl20DIYBVeyDt4Cpjb4GTqQiaWciD1aBg4B9W+20e4t02c/7ImajSLuk0uXcMGCR9Hq1TJnpAlSQrO4VT9yWBXUeihnI8whpQ+ynwwQ4yWtgmHLCiu2XKM60PIduFiQCTWAv1LDYjEd+dOGOeGwR2nAvV7QaQj53zw7azQLW+ZqHxXcMD51NwOaggaw/S0w+L8RPctDcoVKIhg8qgOaZtKDue3vtt0XVFK+CeLPE4ysDVbIt8Wxbq9yG+puoBY3/iCaygQO7fQgOGsHJgIkXfl8NHmEQ6IRW+Namk3PPPEEgQbCvbsyGMYLo/bwcZbjXQtPXnkeiqtDr7FeIjaRN9fgwpuIPtA+NLUfH5bECwe5esF8lIrvF5bCHa64TGYGPTqaOsQz2QpKoZILovRj2cC3jxEZsrkPxICvv4n4XQJPox1bgohuXzxHmqNo3u91u6+NuFyiG1fXoK3ym4JNpB80Tjgj8+GGqcjS4G0ARE0Z0BR7b144gO5Qdkvu3n0iEDLPRuTdMszlqDe4/vSYohActNE8834CZdrygjR7Vgs+jvBrvbp9k+TlWe+dl/ofHZK/7sfq7ds9Z3Dvop4fTO24RQtIJNnKVO4/6nqEclLU+jfsuE/gER6afVhY53xgnAjHb8760yI0o/k4TlRlrk48K+59e6Rzf9t5tkVWtNSjzTmSM0iQoOubZvH976FbKu5Jy+HRV6Lb7w4Guj42EJORzwmPSA5C3EtzXufmtOSZxBF5Qb8T9vShHjnMqlfb8UIZjCPz8f3HofpxmKFuP11piol+845w52ppEbwTIINK7/pV4VbeMqBJ8Ik+4+3gcYYe2H5FqRWn6F/wconjN5alW+F0Er+ZaX2ctVDIuo+sXaQ9B8IJonq8mVWJUvivTj0CIy1UqrURTiX34nyBOc5SxczrzyqFKyTrzy2aCC243vaoZvBqyw6jy60oABspW2rmvMTnkttqdLedHGLywe9UwU7aXvS3K3H1H/jMQ8V8SDsOn28wvx1MY5s+MV91T6T9R4klPetKT/tf0FwPlop4lGFWPAAAAAElFTkSuQmCC);color:transparent;display:block;font-size:0;height:70px;margin:0 0 0 10px;text-decoration:none;width:120px;background-repeat:no-repeat;background-position:center}.hide{display:none}form .btn{border:none;color:#fff;padding:.1em;border-radius:.2em;cursor:pointer;font-size:1.2em;line-height:1em;background:rgba(0,68,136,.1)}.filterForm{border:1px solid rgba(0,68,136,.1);width:120px;margin:0 auto;white-space:nowrap}.filterForm .btn{width:1.2em;height:1.1em}.filterForm #filterText{font-size:1.2em;font-weight:700;border:none;width:95px;color:#379;text-align:center}.phpinfo-nav{bottom:0;padding-left:1.2em;position:fixed;top:70px;width:150px}.phpinfo-nav ul{overflow:auto;list-style:none;padding:.5em 0;margin:0;height:95%}.phpinfo-nav .shade{border:0;margin:0;padding:0;display:block;height:.5em;position:absolute;background:#fff}.phpinfo-nav .shade .top{box-shadow:0 0 10px #fff;top:0}.phpinfo-nav .shade .bottom{box-shadow:0 0 10px #fff;bottom:0}.phpinfo-nav a{color:#37c;padding:.05em .5em;text-decoration:none;display:inline-block}.phpinfo-nav a:hover{text-decoration:underline;text-decoration:dashed}.phpinfo-nav li{border-bottom:1px solid rgba(0,68,136,.1);padding:0 0}.phpinfo-nav li:nth-child(odd){background-color:rgba(68,136,255,.1)}.phpinfo-section{padding:5em 0 0 0}.phpinfo-section h2{color:#379;margin:0 0 0 -10px;position:relative}.phpinfo-section .mark{color:#444;display:inline-block;font-size:1.5em;opacity:.3;position:absolute;right:.5em;text-decoration:none;top:0}.phpinfo-section .mark:hover{opacity:1}.phpinfo-section table{border-collapse:collapse;margin:.5em auto;table-layout:auto;text-align:left}.phpinfo-section td{border-bottom:1px solid #39a;padding:.2em .5em;vertical-align:top}.phpinfo-section td:nth-child(1){font-weight:700;white-space:nowrap}.phpinfo-section td:nth-child(2){word-break:break-word}.phpinfo-section tr:nth-child(odd) td{background-color:#cdf}::-webkit-scrollbar{width:9px;height:9px}::-webkit-scrollbar-button{width:0;height:0}::-webkit-scrollbar-thumb{background:rgba(68,136,255,.1);border:0 none transparent;border-radius:50px}::-webkit-scrollbar-track{background:0 0;border:0 none #fff;border:1px solid rgba(68,136,255,.1);border-radius:50px}::-webkit-scrollbar-track:hover{background:rgba(68,136,255,.1)}::-webkit-scrollbar-track:active{background:rgba(68,136,255,.1)}::-webkit-scrollbar-corner{background:0 0}.golden h1{color:#c90}.golden header .topmenu #gold,.golden header .topmenu a{color:#c90}.golden header .topmenu select{color:#c90;border-color:rgba(204,153,0,.2)}.golden .php-logo{background-image:url(data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAGAAAABgCAMAAADVRocKAAAAA3NCSVQICAjb4U/gAAAAwFBMVEX////MmQD////KlgDJkgDHkQDp0pX+/fv9/Pfx4r3OnQ3r2J/z5sHr15rRohz8+vPFjAD////v37HatUzMmQf69ef27NLt26bjx3XevV3XrjTUqSjSpiPOoRP79+v379fw47ju3KrduljcuFL06MrmzILkynvXrzrv367o0pHYsUD79+v1687gwGPw4bXnz4fgwWnw47j7+O7VqzPUqS358+L48Nvo0I/RoyH1687379f69ef58+L58+L////+/ftn60qRAAAAQHRSTlMA/////////////////////+7/////////////////////////////////qv//////M/////////9VZpmZqt3u3iCtSwAAAAlwSFlzAAAOnAAADpwBB5RT3QAAABx0RVh0U29mdHdhcmUAQWRvYmUgRmlyZXdvcmtzIENTNui8sowAAAZwSURBVGiB7VhnY7o8EC8ZhYIi7r23OFu1dRS//7d6LgsUF/Xv8857RUhyv9y+5O3tRS960YteFNACaLPZAm027PuZnDc71/OS6ISSnufuNv+Ms9juGGe9tm7Eh91CMT3q90ftYqE7tD7WNZ3h7LaPgsDBPYSMXLOQXpoappQSn2CANXOZLgxygOKBKH/n7iaR0Zm1bY1QgrF2gTAGJM1uD8cGSrp/wljsPWQ05hUMvC+xPoEhFFfmDQN5+6gQCxehztyGjfeY+yCU2PMxQm4UiI2LElYfR+euMPDIMpC7uX964/uHkGvqYHQNmpDKMHFHim0SxStXD49H8ff39/jkqnCY/sRRcnv9+B6KlW7ohjZ5jHXp1RUAUYoh74oQ26RRwFeUIyjHAUY31xDc0y8LsUe5r5umxbbB+CfsO/anpRzan/P/RQPz5tE0kuYCjO/6FzGn6Pec//vleD06WY8DxG8fgxHG8TDCHg2V+7Gsc0SBV5IUB2g7csKfOd+BSfxUS1uU9/mXmS8qGvZaZWl4nFlxgIGcKJYywmQ4fbzju5C2AZs00ZGlF6iTUcehhdPEj/RYiysPl/XQzLpbZRN0EPqfSI0IzoxR4K2eUfEVS/LojAYMnrTOJ9Y/oA6tfj7RJaRseIGC5kexc2E5SgEA/b4wMSAa/glLxqhHQBVSSYtDXfMtKZ1dHzQbsdw6q/a2gFGMf3UGqVSq0UmI/zUTS++t5QdsR00hlEmmflhIAYqBAHJ5HUOVgaJV7gmIGMam2AupitGPgIOoo13+lXfY70x1aQmAGaUTKYKbNYMIkM7epNKhnTgff1ZpiX+spDc4Lfkfkyn/KsgdhHSCI7nChawjC5wuB8A2H+u2M+EfU+kNtMiHOd97/QwlbQVqh+TIdLRhCvZNEF5OfAAhikqlZMaHFsFlJYp2MpMDqAli9Werl44AxPJENRQWoEUheVqulSafUyJE6QQBL5L6B9ZInxthF4ADv1ZoORVhESNV7jdGRcwok/cJHfKP9+CQws+HFDwysWMAq8ACSoF+QsNmVmjGGUnNyv8lpRgpykQZjXwhJSps5gDHTqSWKwBpWlR2hKryysZzKakS5cvXqeV7G65+cgC9HITZ6XJMKzXJV2pWeRcRJh8S0LO0kdjhiDjiuYEs9R2Ps6AGSslXmLeJWrUlfOrTJlKzaike82GRSlFSDm84NLsgApMnTwjaLY+DoIrL5es5tLf5xvgTSX1C82YcOyMWJkdLLDXyMe/N3psfdUNsqPHkSWcioXpBEZSSn5LeoioclHeRka+Y8YUdqyUXFOdEPt0hPxDwheX1PggoE45yRhkdDSJz4yk1bL6MlNBOlpu81BE47hn7Am8FZJgpZyQNPpxRKcqxvJ2iLO5QWWTJcZUIcnnig9PU6k5KmiiLmTz/5ftbnA9HRAW62JGyggrLBHCDiilA5fKB4180gsJ+2paqIRHlsuD4NxN/Awjt18w96nHZpbP3bvSGIcqs+Y4LzR5Y7aivcMETNb+6pu93PuqYFe72F5o9SPNuwB+qZgJ8RS437vWGAUnvzZ3z7xuHkxZ4cfjsU1lcclHZ81BiZIVFpv3PQ6jFXhyMtCNSaT66CaT3zkM7aNsI8+eXg3mBdQzTdmQTaBlrChum5RMVYdJD5/w5Qt50eDMRndhVNnTLpXbq2hVkj7Kta9ezqERIK3vpdiBo46HGF/0HCEK/Gsi7cdNc7JEeLz8qBaFLS0d37uPsHmt9/eESrgguyiVgH+EuDjdx9NGqXr8PX+JOqFmEcn73Hi6l2CVRzUqbETGgvpppK4uSu+jvIYstiLHKF9lzyD0UbBab0Nu4f3034hh6zpr3ofdhFy98OUKw3XmAu8TY8PeuWn06K7SXP3bVvADBmvR/eVhbbLaufK8zPlfN6pkHw80qmmVvogDMdv/ruqheCWdCKPvufQ5RaYOypTACaaInvnFuDkYx5FbQ7T5RBJZzLfNUCKg6V7PbIwi/aNU+yVYYN9D1R6gH6Czn4mruuQiQc5G1PJKC2E9GYDlXb46Cp0lSjaE/ZKKIEPxxVboUzsSvPtU9DLHzUCJVtMXzMCaTxJPVpB64Y72+yZKuU4ndrJYPYmwBA2Vjs2K5Spzi2vh9sp7eRDo8sAZ1nPoerlAi8hv5n0Ags/96HhQQHemJ/0EKBfPGsu5u92SPfdGLXvSiF739B4fNoGmVqmhUAAAAAElFTkSuQmCC)}.golden form .btn{background:rgba(204,153,0,.2)}.golden .filterForm{border-color:rgba(204,153,0,.3)}.golden .filterForm #filterText{color:#c90}.golden .phpinfo-nav{border-right-color:transparent}.golden .phpinfo-nav li{border-bottom-color:rgba(204,153,0,.3)}.golden .phpinfo-nav li:nth-child(odd){background-color:rgba(204,153,0,.2)}.golden .phpinfo-nav a{color:#c90}.golden .phpinfo-section h2{color:#c90}.golden .phpinfo-section .mark{color:#444}.golden .phpinfo-section td{border-bottom-color:#c90}.golden .phpinfo-section tr:nth-child(odd) td{background-color:rgba(204,153,0,.3)}.golden ::-webkit-scrollbar-thumb{background:rgba(204,153,0,.3)}.golden ::-webkit-scrollbar-track{border-color:rgba(204,153,0,.3)}.golden ::-webkit-scrollbar-track:hover{background:rgba(204,153,0,.3)}.golden ::-webkit-scrollbar-track:active{background:rgba(204,153,0,.3)}</style>
</head>
<body>
	<nav id="toc">
		<a href="<?php echo  $_SERVER['PHP_SELF'] ?>" title="" class="php-logo">Renew</a>
		<?php echo  $phpinfo->nav ?>
	</nav>
	<header>
		<h1>v.<?php echo  PHP_VERSION ?> </h1>
		<ul class="topmenu">
			<li><em id="gold">Colors</em></li>
			<li>
				<form action="" method="GET" id="formShowNative">					
					<input type="hidden" name="do" value="native">
					<select name="mode" id="nativeMode">
						<optgroup>
							<option selected>Show native with…</option>
						</optgroup>
						<optgroup>
							<option value="1" >INFO_GENERAL</option>
							<option value="2" >INFO_CREDITS</option>
							<option value="4" >INFO_CONFIGURATION</option>
							<option value="8" >INFO_MODULES</option>
							<option value="16">INFO_ENVIRONMENT</option>
							<option value="32">INFO_VARIABLES</option>
							<option value="64">INFO_LICENSE</option>
						</optgroup>
						<optgroup>
							<option value="-1">INFO_ALL</option>
						</optgroup>
					</select>
					<button type="submit" class="btn">&#10151;</button>
				</form>
			</li>
			<li><a href="?do=update" title="Force update from GitHub">v.<?= PPI_VERSION ?></a></li>
		</ul>
	</header>
	<article>
	<?php echo  $phpinfo->content ?>
	</article>

<!-- <script src="info.js"></script> -->
<script>(function(b){function c(a,b){Array.prototype.forEach.call(a,b)}function d(a){return a.innerText||a.textContent}function g(){k.href=window.getComputedStyle(b.getElementsByClassName("php-logo")[0],null).getPropertyValue("background-image").match(/url\(("?)(.+)\1\)/)[2]}window.$=function(a){return b[{"#":"getElementById",".":"getElementsByClassName","@":"getElementsByName","=":"getElementsByTagName"}[a[0]]||"querySelectorAll"](a)};"true"===localStorage.getItem("phpInfoGold")&&b.body.classList.add("golden");
var k=b.getElementById("docIcon");g();b.getElementById("gold").addEventListener("click",function(a){b.body.classList.toggle("golden");localStorage.setItem("phpInfoGold",b.body.classList.contains("golden"));g()});var e=$("td:nth-child(2)"),l="Windows"===d(e[0]).match(/^\w+/)[0]?/[;,]/g:/[:,]/g;c(e,function(a,b){e[b].innerHTML=d(a).replace(l,"$& ")});var h=$(" .phpinfo-nav li"),f=$(" .phpinfo-section");b.getElementById("filterText").addEventListener("input",function(a){var b=new RegExp(a.target.value,
"i");c(h,function(a,c){0>d(a).search(b)?(a.classList.add("hide"),f[c].classList.add("hide")):(a.classList.remove("hide"),f[c].classList.remove("hide"))})});b.getElementsByClassName("filterForm")[0].addEventListener("reset",function(a){c(h,function(a,b){a.classList.remove("hide");f[b].classList.remove("hide")})});b.body.addEventListener("keyup",function(a){"Escape"===a.code&&b.getElementsByClassName("filterForm")[0].reset()});nativeMode.addEventListener("change",function(a){formShowNative.submit()})})(document);
</script>
</body>
</html>