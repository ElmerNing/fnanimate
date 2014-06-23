/*
path
*/

var path_sep = "/"
function __path_split(path)
{
	return path.split(path_sep)
}

function path_basename(path)
{
	var splits = __path_split(path)
	return splits[splits.length-1]
}

function path_dir(path)
{
	var splits = __path_split(path)
	splits = splits.slice(0, splits.length-1)
	return splits.join(path_sep)
}

function path_join(dir, filename)
{
    if (dir.charAt(dir.length-1) == path_sep)
	{
		 return dir + filename
	}
    else
	{
		 return dir + path_sep + filename
	}
}


var items = fl.getDocumentDOM().library.items
for(var i in items)
{
	var item = items[i]
	if (item.itemType == "bitmap")
	{
		var dir = path_dir(fl.scriptURI)
		var filepath = path_join(dir, item.name)
		item.exportToFile(filepath)
	}
}