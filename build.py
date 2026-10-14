"""Builds index.html from src/app.html and the data folder.  Run:  python3 build.py"""
import base64, json, re, os
here = os.path.dirname(os.path.abspath(__file__)); os.chdir(here)
ld = lambda p: json.load(open(p, encoding='utf-8'))
B = {}
for key, f in [('shatharat1','shatharat1'),('shatharat2','shatharat2'),('aja','aja'),('anwar','anwar'),('anwar-en','anwar_en'),('khurbut','khurbut'),('darebestan','darebestan')]:
    B[key] = ld('data/books/%s.json' % f)
j = lambda x: json.dumps(x, ensure_ascii=False, separators=(',',':')).replace('<','\\u003c')
b64 = lambda p, m: 'data:%s;base64,%s' % (m, base64.b64encode(open(p,'rb').read()).decode())
s = open('src/app.html', encoding='utf-8').read()
import hashlib, glob
covv = hashlib.md5(b''.join(open(f,'rb').read() for f in sorted(glob.glob('assets/covers/*.jpg')))).hexdigest()[:8]
s = s.replace('__COVV__', covv)
for ph, val in [('__BOOKS_JSON__', j(B)), ('__TERMS_JSON__', j(ld('data/terms.json'))), ('__PROVERBS_JSON__', j(ld('data/proverbs.json'))),
                ('__IGNORED_JSON__', j(ld('data/ignored.json'))), ('__LEX__', ' '.join(ld('data/lex.json'))), ('__SUGG_JSON__', j(ld('data/sugg.json'))),
                ('__MEDIA_JSON__', j(ld('data/media.json'))), ('__LOGO__', b64('assets/logo-crop.png','image/png')),
                ('__THUMB__', b64('assets/author.jpg','image/jpeg')), ('__PHOTO__', b64('assets/face240.jpg','image/jpeg'))]:
    s = s.replace(ph, val)
assert not re.search(r'__[A-Z_]+_JSON__|__(LEX|LOGO|THUMB|PHOTO)__', s)
head = '''<!doctype html>
<html lang="ar" dir="rtl">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover">
<title>حكايا رائد حجازي</title>
<meta name="description" content="كتب الكاتب رائد عبدالرحمن حجازي ومعجم المفردات التراثية الأردنية">
<meta name="theme-color" content="#336E6A">
<link rel="manifest" href="manifest.webmanifest?v=3">
<link rel="icon" type="image/png" href="assets/favicon-64.png?v=3">
<link rel="apple-touch-icon" href="assets/icon-180.png?v=3">
<meta name="apple-mobile-web-app-capable" content="yes">
<meta name="apple-mobile-web-app-title" content="حكايا رائد">
<style>html,body{margin:0;padding:0}img{max-width:100%}[hidden]{display:none!important}</style>
<script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2.45.4/dist/umd/supabase.js" defer></script>
</head>
<body>
'''
open('index.html', 'w', encoding='utf-8').write(head + s + '\n</body>\n</html>\n')
print(round(len(s.encode())/1e6, 2), 'MB')
