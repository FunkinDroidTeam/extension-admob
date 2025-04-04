package util;

import haxe.io.Path;
import sys.FileSystem;
import sys.io.File;

/**
 * Utility class for file system operations.
 */
class FileUtil
{
	/**
	 * Recursively deletes a file or directory at the given path.
	 * If the path is a directory, all its contents will be deleted.
	 * 
	 * @param path The path to the file or directory to delete.
	 */
	public static function deletePath(path:String):Void
	{
		if (!FileSystem.exists(path))
			return;

		if (FileSystem.isDirectory(path))
		{
			// Delete all files and subdirectories in the directory
			for (file in FileSystem.readDirectory(path))
				deletePath(Path.join([path, file]));

			FileSystem.deleteDirectory(path);
		}
		else
			FileSystem.deleteFile(path);
	}

	/**
	 * Creates a directory and any parent directories at the specified path.
	 * The path is normalized and trailing slashes are removed before creating directories.
	 * 
	 * @param path The path where the directory will be created.
	 */
	public static function createDirectory(path:String):Void
	{
		if (path == null || path.length == 0)
			return;

		// Normalize and remove trailing slashes
		path = Path.removeTrailingSlashes(Path.normalize(path));

		var currentPath:String = '';

		// Create each part of the path as a directory
		for (part in path.split('/'))
		{
			if (part.length == 0)
				continue;

			currentPath += Path.addTrailingSlash(part);

			if (!FileSystem.exists(currentPath))
				FileSystem.createDirectory(currentPath);
		}
	}

	/**
	 * Copies a directory and its contents from the source to the destination path.
	 * Creates the destination directory if it does not exist.
	 * 
	 * @param src The path to the source directory.
	 * @param dest The path to the destination directory.
	 */
	public static function copyDirectory(src:String, dest:String)
	{
		// Create destination directory if it does not exist
		if (!FileSystem.exists(dest))
			createDirectory(dest);

		// Copy each file or directory from source to destination
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
}
