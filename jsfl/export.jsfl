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

/*
helper function
*/
function traceObject(obj)
{
    if (typeof obj == "object"  )
    {
        //fl.trace(obj);
        for (var i in obj)
        {
			try
			{
            	var s= i + " : " + obj[i]
				fl.trace(s);
			}
			catch (err)
			{
				fl.trace("error " + i + " : null")
			}

            
        }
    }
    else
    {
        fl.trace(obj);
    }
}

function getType(x){  
    if(x==null){  
        return "null";  
    }  
    var t= typeof x;  
    if(t!="object"){  
        return t;  
    }  
    var c=Object.prototype.toString.apply(x);  
    c=c.substring(8,c.length-1);  
    if(c!="Object"){  
        return c;  
    }  
    if(x.constructor==Object){  
        return c  
    }  
    if("classname" in x.prototype.constructor  
            && typeof x.prototype.constructor.classname=="string"){  
        return x.constructor.prototype.classname;  
    }  
    return "<unknown type>";  
}


function get_layer_all_keyframe(layer)
{
	var keyframes = new Array()
	for (var i in layer.frames)
	{
		var frame = layer.frames[i]
		if (i == frame.startFrame)
			keyframes.push(frame)
	}
	return keyframes
}

var get_all_template = (function(){
    var unique = {};

    var template_dir = path_join(path_dir( fl.scriptURI ) , "template")
    {
        var main_template = FLfile.read( path_join(template_dir, "main.template") )
        unique["main"] = main_template
		
        var timeline_template = FLfile.read( path_join(template_dir, "timeline.template") )
        unique["timeline"] = timeline_template

        var layer_template = FLfile.read( path_join(template_dir, "layer.template") )
        unique["layer"] = layer_template

        var keyframe_template = FLfile.read( path_join(template_dir, "keyframe_ofs.template") )
        unique["keyframe_ofs"] = keyframe_template
		
        var keyframe_template = FLfile.read( path_join(template_dir, "keyframe_mfs.template") )
        unique["keyframe_mfs"] = keyframe_template

		var keyframe_template = FLfile.read( path_join(template_dir, "keyframe_empty.template") )
        unique["keyframe_empty"] = keyframe_template
    }

    return function() { return unique } 
	
})()

var get_skins = (function(){
    var unique = new Array();
    return function() { return unique }
})()

/*
one frame symbol 单帧元件
*/
function ofs_belong(symbol)
{
    var layers = symbol.libraryItem.timeline.layers
    var is_one_frame = layers.length == 1 && layers[0].frames.length == 1 && layers[0].frames[0].elements.length == 1

    if (is_one_frame) 
	{
        return true
    }
	else
	{
		return false
	}
}

function ofs_get_bitmap_item(symbol)
{
	var layers = symbol.libraryItem.timeline.layers
    var bitmap = layers[0].frames[0].elements[0].libraryItem
	return bitmap
}


/*
export function
*/

function export_keyframe(keyframe, index)
{
	var element = keyframe.elements[0]
	if (element == null || element.elementType != "instance" || element.instanceType != "symbol")
	{
		return export_empty_keyframe(keyframe)
	}
    else
    {
        var symbol = element
        if (ofs_belong(symbol))
        {
            return export_ofs_keyframe(keyframe)  
        }
        else
        {
            return export_mfs_keyframe(keyframe)
        }
    }
}

function export_empty_keyframe(keyframe)
{
	return get_all_template()["keyframe_empty"].replace("[idx]", keyframe.startFrame)
}

function export_ofs_keyframe(keyframe)
{
	var element = keyframe.elements[0]
	var bitmap = ofs_get_bitmap_item(element)
	var template = get_all_template()["keyframe_ofs"]
    template = template.replace("[idx]", keyframe.startFrame)
    template = template.replace("[x]", element.transformX)
    template = template.replace("[y]", -element.transformY)
    template = template.replace("[sx]", element.scaleX)
    template = template.replace("[sy]", element.scaleY)
    template = template.replace("[tx]", element.getTransformationPoint().x)
    template = template.replace("[ty]", -element.getTransformationPoint().y)
    template = template.replace("[r]", element.rotation)
	template = template.replace("[skin]", bitmap.name)
    template = template.replace("[blend]", element.blendMode)
    template = template.replace("[name]", keyframe.name)
	
    //补间
    if (keyframe.tweenType == "none")
        template = template.replace("[tw]", false)
	else
        template = template.replace("[tw]", true)

    //透明度
    if (element.colorMode == "alpha")
    {
        template = template.replace("[alpha]", element.colorAlphaPercent) 
    }
    else
    {
        template = template.replace("[alpha]", 100) 
    }

	return template
}

function export_mfs_keyframe(keyframe)
{
    return export_empty_keyframe(keyframe)
}

function export_layer(layer)
{	
	var keyframes = get_layer_all_keyframe(layer)
	var keyframes_data = ""
	for (var i in keyframes)
	{
       keyframes_data += export_keyframe(keyframes[i], i)
	}
	
	return get_all_template()["layer"].replace("[name]", layer.name).replace("[frameCount]",layer.frameCount).replace("[keyframes]", keyframes_data)
}

function export_timeline(timeline)
{
	var layers_data = ""

	for (var i in timeline.layers)
	{
		layers_data += export_layer(timeline.layers[i])
	}

    return get_all_template()["timeline"].replace("[layers]", layers_data)
}

function export_Item(item)
{
	var document = fl.getDocumentDOM()
	
    var timeline = export_timeline( item.timeline )
	
    var template = get_all_template()["main"]
    template = template.replace("[timeline]", timeline)

	return template
}

function export_fl()
{
	var document = fl.getDocumentDOM()
	
    var timeline = export_timeline( document.getTimeline() )
	
    var template = get_all_template()["main"]
    template = template.replace("[timeline]", timeline)

	return template
}

//
//fl.trace( fl.scriptURI )
/*
var items = fl.getDocumentDOM().library.getSelectedItems()

for (var i in items)
{
	var item = items[i]
	if (item.itemType == "movie clip")
	{
		var itemdata = export_Item(item)
		fl.trace(itemdata)
	}
}*/
//fl.trace(export_timeline(timeline))
//FLfile.write( path_dir( fl.scriptURI ) + "/abc.lua", timeline )
//var timeline = fl.getDocumentDOM().getTimeline()
//export_timeline(timeline)

fl.trace(export_fl())




