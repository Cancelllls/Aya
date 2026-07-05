export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    const pathParts = url.pathname.split('/').filter(p => p);
    
    // Default response for root or invalid paths
    if (pathParts.length === 0) {
      return new Response('Quran Audio Proxy is running with R2 caching!', { status: 200 });
    }

    const bucketPath = url.pathname.substring(1); // e.g. audio/ar.alafasy/1/1.mp3
    let targetUrl = '';

    // 1. Try to fetch from Cloudflare R2 bucket directly
    const object = await env.QURAN_AUDIO.get(bucketPath);
    if (object) {
      const headers = new Headers();
      object.writeHttpMetadata(headers);
      headers.set('etag', object.httpEtag);
      if (!headers.has('Content-Type')) {
        headers.set('Content-Type', 'audio/mpeg');
      }
      return new Response(object.body, { headers });
    }

    // 2. If not found in R2, determine origin target URL to proxy
    if (pathParts[0] === 'audio') {
      if (pathParts.length === 4) {
        // Ayah audio: /audio/{reciter}/{surah}/{ayah}.mp3
        const reciter = pathParts[1];
        const surah = pathParts[2];
        const ayah = pathParts[3].replace('.mp3', '');
        
        const surahPadded = surah.padStart(3, '0');
        const ayahPadded = ayah.padStart(3, '0');
        
        const reciterMap = {
          'ar.alafasy': 'Alafasi_128kbps',
          'ar.abdulbasit': 'Abdul_Basit_Mujawwad_128kbps',
          'ar.husary': 'Husary_128kbps',
          'ar.minshawi': 'Minshawy_Mujawwad_192kbps',
          'ar.shuraym': 'Saood_ash-Shuraym_128kbps',
          'ar.sudais': 'Abdurrahmaan_As-Sudais_192kbps',
          'ar.maher': 'Maher_AlMuaiqly_64kbps',
        };
        
        const folder = reciterMap[reciter] || 'Alafasi_128kbps';
        targetUrl = `https://everyayah.com/data/${folder}/${surahPadded}${ayahPadded}.mp3`;
        
      } else if (pathParts.length === 3) {
        // Surah audio: /audio/{reciter}/{surah}.mp3
        const reciter = pathParts[1];
        const surah = pathParts[2].replace('.mp3', '');
        
        const surahPadded = surah.padStart(3, '0');
        
        const reciterMap = {
          'ar.alafasy': 'afs',
          'ar.abdulbasit': 'basit/mjwd',
          'ar.husary': 'husr',
          'ar.minshawi': 'minsh/mjwd',
          'ar.shuraym': 'shur',
          'ar.sudais': 'sds',
          'ar.maher': 'maher',
        };
        
        const folder = reciterMap[reciter] || 'afs';
        targetUrl = `https://server8.mp3quran.net/${folder}/${surahPadded}.mp3`;
      }
    } else if (pathParts[0] === 'adhan') {
      // Adhan audio proxy
      const filename = pathParts[1];
      targetUrl = `https://raw.githubusercontent.com/Five-Prayers/five-prayers-android/main/app/src/main/res/raw/${filename}`;
    }
    
    // 3. Fetch from origin and cache in R2 in the background
    if (targetUrl) {
      // Forward request avoiding origin caching headers if necessary
      const response = await fetch(targetUrl, {
        method: request.method,
        headers: request.headers
      });
      
      if (response.ok) {
        // Wait until caching is done to avoid dropping the connection prematurely
        ctx.waitUntil(env.QURAN_AUDIO.put(bucketPath, response.clone().body, {
          httpMetadata: { contentType: 'audio/mpeg' }
        }));
        
        const headers = new Headers(response.headers);
        headers.set('Content-Type', 'audio/mpeg');
        return new Response(response.body, { 
          status: response.status,
          headers: headers 
        });
      } else {
        return new Response('File not found at origin', { status: response.status });
      }
    }

    return new Response('Not Found', { status: 404 });
  }
}
