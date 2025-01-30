package;

import sys.io.File;
import haxe.io.Path;
import sys.FileSystem;
import sys.io.Process;

@:nullSafety
class Main
{
	@:noCompletion
	private static final URLS:Map<String, String> = [
		'googlemobileadssdkios.zip' => 'https://dl.google.com/googleadmobadssdk/googlemobileadssdkios.zip',
		'UnityAdapter-4.12.5.0.zip' => 'https://dl.google.com/googleadmobadssdk/mediation/ios/unity/UnityAdapter-4.12.5.0.zip'
	];

	@:noCompletion
	private static final OUTPUT_DIR:String = 'project/admob-ios/frameworks';

	@:noCompletion
	private static final TEMP_DIR:String = '.temp_sdk';

	public static function main():Void
	{
		if (Sys.systemName() != 'Mac')
		{
			printlnColor('You can only run this script on MacOS.', AnsiColor.Red);

			Sys.exit(1);
		}

		final libPath:Null<String> = libPath('extension-admob');

		if (libPath == null)
		{
			printlnColor('Unable to find "extension-admob" path.', AnsiColor.Red);

			Sys.exit(1);
		}
		else
			Sys.setCwd(libPath);

		deleteDirectory(OUTPUT_DIR);
		createDirectory(OUTPUT_DIR);

		deleteDirectory(TEMP_DIR);
		createDirectory(TEMP_DIR);

		for (key => value in URLS)
		{
			printlnColor('Downloading $key from $value...', AnsiColor.Blue);

			final result:Int = Sys.command('curl', ['-o', key, value]);

			if (result != 0)
			{
				printlnColor('Failed to download $key.', AnsiColor.Red);

				Sys.exit(result);
			}

			printlnColor('Unzipping $key to $TEMP_DIR...', AnsiColor.Blue);

			final result:Int = Sys.command('unzip', ['-q', key, '-d', TEMP_DIR]);

			if (result != 0)
			{
				printlnColor('Failed to unzip $key.', AnsiColor.Red);

				Sys.exit(result);
			}
		}

		for (file in FileSystem.readDirectory(TEMP_DIR))
		{
			final oldCwd:String = Sys.getCwd();

			final path:String = Path.join([TEMP_DIR, file]);

			Sys.setCwd(path);

			if (FileSystem.isDirectory(path) && Path.extension(file) == "xcframework")
			{
				for (archDir in FileSystem.readDirectory(path))
				{
					final archPath:String = Path.join([path, archDir]);

					if (FileSystem.isDirectory(archPath) && archDir.indexOf("ios-") == 0)
					{
						printlnColor('Found architecture directory: $archDir', AnsiColor.Blue);

						final frameworkDir:Null<String> = findFrameworkDirectory(archPath);

						if (frameworkDir != null)
						{
							final archName:String = extractArchName(archDir);
							final destDir:String = Path.join([OUTPUT_DIR, archName]);
							final frameworkName:String = Path.withoutDirectory(frameworkDir);
							final destPath:String = Path.join([destDir, frameworkName]);

							printlnColor('Copying $frameworkName to $destDir', AnsiColor.Blue);

							copyDirectory(frameworkDir, destPath);
						}
						else
							printlnColor('No .framework file found in $archDir', AnsiColor.Blue);
					}
				}
			}

			Sys.setCwd(oldCwd);
		}

		printlnColor('Cleaning up...', AnsiColor.Blue);

		deleteDirectory(TEMP_DIR);

		printlnColor('Frameworks have been organized in $OUTPUT_DIR!', AnsiColor.Blue);
	}

	@:noCompletion
	private static function libPath(lib:String):Null<String>
	{
		return new Process('haxelib', ['path', lib]).stdout.readLine();
	}

	@:noCompletion
	private static function deleteDirectory(path:String):Void
	{
		if (FileSystem.isDirectory(path))
		{
			for (file in FileSystem.readDirectory(path))
				deleteDirectory(Path.join([path, file]));

			FileSystem.deleteDirectory(path);
		}
		else
			FileSystem.deleteFile(path);
	}

	@:noCompletion
	private static function createDirectory(path:String):Void
	{
		if (path == null || path.length == 0)
			return;

		path = Path.removeTrailingSlashes(Path.normalize(path));

		var currentPath:String = '';

		for (part in path.split('/'))
		{
			if (path.length == 0)
				continue;

			currentPath += Path.addTrailingSlash(part);

			if (!FileSystem.exists(currentPath))
				FileSystem.createDirectory(currentPath);
		}
	}

	@:noCompletion
	private static function copyDirectory(src:String, dest:String)
	{
		if (!FileSystem.exists(dest))
			createDirectory(dest);

		for (file in FileSystem.readDirectory(src))
		{
			final srcPath:String = Path.join([src, file]);
			final destPath:String = Path.join([dest, file]);

			if (FileSystem.isDirectory(srcPath))
				copyDirectory(srcPath, destPath);
			else
				File.copy(srcPath, destPath);
		}
	}

	@:noCompletion
	private static function findFrameworkDirectory(directory:String):Null<String>
	{
		for (file in FileSystem.readDirectory(directory))
		{
			final path:String = Path.join([directory, file]);

			if (FileSystem.isDirectory(path) && Path.extension(file) == "framework")
				return path;
		}

		return null;
	}

	@:noCompletion
	private static function extractArchName(dirName:String):String
	{
		final regex:EReg = ~/^ios-(.+)/;

		if (regex.match(dirName))
			return regex.matched(1);

		return dirName;
	}

	@:noCompletion
	private static function printlnColor(input:String, ansiColor:AnsiColor):Void
	{
		#if sys
		Sys.println('$ansiColor$input${AnsiColor.None}');
		#else
		Sys.println(input);
		#end
	}
}

enum abstract AnsiColor(String) from String to String
{
	var Black = '\033[0;30m';
	var Red = '\033[0;31m';
	var Green = '\033[0;32m';
	var Yellow = '\033[0;33m';
	var Blue = '\033[0;34m';
	var Magenta = '\033[0;35m';
	var Cyan = '\033[0;36m';
	var Gray = '\033[0;37m';
	var White = '\033[1;37m';
	var None = '\033[0;0m';
}
