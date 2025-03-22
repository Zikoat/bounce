type x
@val external x: x = "x"
@set external setOnload: (x, @this ((x, int) => unit)) => unit = "onload"
@get external resp: x => int = "response"
setOnload(x, @this (o, v) => Console.log(resp(o) + v))
