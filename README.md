Build Kitsu with simple bash command

1. Clone repository:
```bash
git clone https://github.com/anton-MS/kitsu-final.git
```
```bash
cd kitsu-final
```

2. Give X permission to the bin folder to be able to run the scripts:
```bash
chmod -R +x bin/
```

3. Now the build starts and also will add some content into DB. After building (it will take around 5 min) you can open API page for this link:
```bash
http://localhost/
```
And WEB ui by this link:
```bash
http://localhost:5173/
```

4. In order to see some content (as long as ui is a bit broken) we can put the exact page in browser url for example:
```bash
http://localhost:5173/anime/one-piece
```

5. Now we have running API / WEB UI running locally for Kitsu application with some content. 
