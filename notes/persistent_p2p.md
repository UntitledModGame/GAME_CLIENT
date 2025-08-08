
## SUPER COOL IDEA: "Persistent p2p"
People just wanna play games with friends. It's pretty simple.

However, the core issue with p2p is that since there's 1 friend hosting the server, you can't play unless that friend is online.
EG:
```
GAME:
Max (host)
Barry
John
```
Barry and john can come and go, but as soon as Max leaves, the server dies.
And if John and Barry want to play on their own, they can't; because Max has the server.

This is the exact reason why people pay for minecraft Realms; people just want a easy way to play with friends.
HOWEVER, we can solve this:

when Max logs off, the world-save should be serialized and sent to a centralized server, (stored in s3 bucket or something)
And then when Barry or John wants to play, they can start hosting the game themselves, and the world-save is grabbed from S3.

You get all the benefits of realms without any of the downsides! And its way cheaper than a central server.

