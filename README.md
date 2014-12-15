#基本介紹
這個範例主要是介紹一個利用 Audio Queue 建造的播放器。主要可以分為三大部分。

#抓取檔案 NJAudioFileFetcher
我們使用 iOS 7.0 之後才有的 NSURLSession 去抓取音檔。只要抓到部分的音檔我們都會利用 delegate 的方式丟給 NJPlayer，讓 NJPlayer 去處理。

#轉換檔案格式 NJAudioStreamParser
NJAudioStreamParser 可以藉由 NJPlayer 從 NJAudioFileFetcher 拿到需要剖析的 raw data。parser 最關心的其實是 raw data 中的兩個關鍵資料。

- 只要 parser 在這些不全的資料中找到 AudioStreamBasicDescription (ASBD)它就會利用 delegate 的方式通知 NJPlayer 處理。
- 找到 ASBD 後，只要 parser 找到一個完整的 packet 它也會再把資料利用 delegate 的方式丟給 NJPlayer。

#播歌 NJAudioQueue
- NJAudioQueue 可以藉由 NJPlayer 從 NJAudioStreamParser 得到 ASBD ，在得到了 audioQueue 所需要的 ASBD 後我們就可以利用 AudioQueueNewOutput 建立 audioQueue 準備來播放歌曲了。另外，在建立 audioQueue 的同時也要設定兩個特定時間點的 callback。一個是 AudioQueueOutputCallback 它可以告訴我們某個 audioQueueBuffer 已經播完了所以我們可以在這個時間點利用 AudioQueueFreeBuffer 釋放 buffer。另一個是要監聽 audioQueue 中 kAudioQueueProperty_IsRunning 這個屬性，它的變動代表著我們要去處理歌曲開始/停止播放的後續動作。
- 接著 NJAudioQueue 也會藉由 NJPlayer 從 NJAudioStreamParser 陸續得到部分的 packet。此時，我們就可以利用 AudioQueueAllocateBufferWithPacketDescriptions 製造出 buffer 然後再利用 AudioQueueEnqueueBuffer 將 buffer enqueu 進 audio queue 裡。

#需要實作所有 delegate 的物件 NJPlayer
這個物件等於是 NJAudioFileFetcher、NJAudioStreamParser 以及 NJAudioQueue 協調彼此之間資料的中間人。

#TODO
- 播放進度條
- audio queue 可以播放歌曲的真正時機點
