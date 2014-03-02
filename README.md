#基本介紹
這個範例主要是介紹一個利用 Audio Queue 建造的播放器。主要可以分為三大部分。

#抓取檔案 NJAudioFileFetcher
我們使用 iOS 7.0 之後才有的 NSURLSession 去抓取音檔。只要抓到部分的音檔我們都會利用 delegate 的方式丟給 NJPlayer，讓 NJPlayer 去處理。

#轉換檔案格式 NJAudioStreamParser
NJAudioStreamParser 可以藉由 NJPlayer 從 NJAudioFileFetcher 拿到需要剖析的 raw data。parser 最關心的其實是 raw data 中的兩個關鍵資料。

- 只要 parser 在這些不全的資料中找到 AudioStreamBasicDescription (	ASBD)它就會利用 delegate 的方式通知 NJPlayer 處理。
- 找到 ASBD 後，只要 parser 找到一個完整的 packet 它也會再把資料利用 delegate 的方式丟給 NJPlayer。

#播歌 NJAudioQueue
- NJAudioQueue 可以藉由 NJPlayer 從 NJAudioStreamParser 得到 ASBD ，也就是說 audio queue 得到了播歌所需要的 metadata 於是我們就可以建立 audio queue 準備來播放歌曲了。
- 接著 NJAudioQueue 也會藉由 NJPlayer 從 NJAudioStreamParser 陸續得到部分的 packet。此時，我們就可以讓 audio queue alloc 出 buffer 的位置以便讓這些 packets 資料能夠 enqueue 進 audio queue 裡。

#需要實作所有 delegate 的物件 NJPlayer
這個物件等於是 NJAudioFileFetcher、NJAudioStreamParser 以及 NJAudioQueue 協調彼此之間資料的中間人。

#TODO
- 播放進度條
- audio queue 可以播放歌曲的真正時機點
