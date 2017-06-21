package util;

class RandTools
{
	public static function randInt() :Int
	{
		return Std.int(Math.random() * 10000000);
	}
}