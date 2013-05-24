require 'algolia/client'
require 'algolia/error'

module Algolia
  
  class Index
    attr_accessor :name
    
    def initialize(name)
      self.name = name
    end
    
    # Delete an index
    # 
    # return an object whith in the form array(:deletedAt => "2013-01-18T15:33:13.556Z")
    def delete
      Algolia.client.delete(Protocol.index_uri(name))
    end

    # Add an object in this index
    # 
    # @param content contains the object to add inside the index. 
    #  The object is represented by an associative array
    # @param objectID (optional) an objectID you want to attribute to this object 
    #  (if the attribute already exist the old object will be overwrite)
    def add_object(obj, objectID = nil)
      if objectID == nil
        Algolia.client.post(Protocol.index_uri(name), obj.to_json)
      else
        Algolia.client.put(Protocol.object_uri(name, objectID), obj.to_json)        
      end
    end
    
    # Add an object in this index and wait end of indexing
    # 
    # @param content contains the object to add inside the index. 
    #  The object is represented by an associative array
    # @param objectID (optional) an objectID you want to attribute to this object 
    #  (if the attribute already exist the old object will be overwrite)
    def add_object!(obj, objectID = nil)
      res = add_object(obj, objectID)
      wait_task(res["taskID"])
      return res
    end

    # Add several objects in this index
    # 
    # @param content contains the object to add inside the index. 
    #  The object is represented by an associative array
    # @param objectID (optional) an objectID you want to attribute to this object 
    #  (if the attribute already exist the old object will be overwrite)
    def add_objects(objs)
        requests = []
        objs.each do |obj|
            requests.push({"action" => "addObject", "body" => obj})
        end
        request = {"requests" => requests};
        Algolia.client.post(Protocol.batch_uri(name), request.to_json)
    end
    
    # Add several objects in this index and wait end of indexing
    # 
    # @param content contains the object to add inside the index. 
    #  The object is represented by an associative array
    # @param objectID (optional) an objectID you want to attribute to this object 
    #  (if the attribute already exist the old object will be overwrite)
    def add_objects!(obj)
      res = add_objects(obj)
      wait_task(res["taskID"])
      return res
    end

    # Search inside the index
    #
    # @param query the full text query
    # @param args (optional) if set, contains an associative array with query parameters:
    #  - attributes: a string that contains attribute names to retrieve separated by a comma. 
    #    By default all attributes are retrieved.
    #  - attributesToHighlight: a string that contains attribute names to highlight separated by a comma. 
    #    By default all attributes are highlighted.
    #  - minWordSizeForApprox1: the minimum number of characters in a query word to accept one typo in this word. 
    #    Defaults to 3.
    #  - minWordSizeForApprox2: the minimum number of characters in a query word to accept two typos in this word.
    #     Defaults to 7.
    #  - getRankingInfo: if set to 1, the result hits will contain ranking information in 
    #     _rankingInfo attribute
    #  - page: (pagination parameter) page to retrieve (zero base). Defaults to 0.
    #  - hitsPerPage: (pagination parameter) number of hits per page. Defaults to 10.
    #  - aroundLatLng let you search for entries around a given latitude/longitude (two float separated 
    #    by a ',' for example aroundLatLng=47.316669,5.016670). 
    #    You can specify the maximum distance in meters with aroundRadius parameter (in meters).
    #    At indexing, geoloc of an object should be set with _geoloc attribute containing lat and lng attributes (for example {"_geoloc":{"lat":48.853409, "lng":2.348800}})
    #  - insideBoundingBox let you search entries inside a given area defined by the two extreme points of 
    #    a rectangle (defined by 4 floats: p1Lat,p1Lng,p2Lat, p2Lng.
    #    For example insideBoundingBox=47.3165,4.9665,47.3424,5.0201).
    #    At indexing, geoloc of an object should be set with _geoloc attribute containing lat and lng attributes (for example {"_geoloc":{"lat":48.853409, "lng":2.348800}})
    #  - tags let you filter the query by a set of tags (contains a list of tags separated by ','). 
    #    At indexing, tags should be added in _tags attribute of objects (for example {"_tags":["tag1","tag2"]} )
    #
    def search(query, params = {})
      Algolia.client.get(Protocol.search_uri(name, query, params))
    end

    #
    # Get an object from this index
    # 
    # @param objectID the unique identifier of the object to retrieve
    # @param attributesToRetrieve (optional) if set, contains the list of attributes to retrieve as a string separated by ","
    #
    def get_object(objectID, attributesToRetrieve = nil)
      if attributesToRetrieve == nil
        Algolia.client.get(Protocol.object_uri(name, objectID, nil))
      else
        Algolia.client.get(Protocol.object_uri(name, objectID, {"attributes" => attributesToRetrieve}))
      end
    end

    # Wait the publication of a task on the server. 
    # All server task are asynchronous and you can check with this method that the task is published.
    #
    # @param taskID the id of the task returned by server
    # @param timeBeforeRetry the time in milliseconds before retry (default = 100ms)
    #    
    def wait_task(taskID, timeBeforeRetry = 100)
      loop do
        status = Algolia.client.get(Protocol.task_uri(name, taskID))["status"]
        if status == "published"
            return
        end
        sleep(timeBeforeRetry / 1000)
      end
    end

    # Override the content of object
    # 
    # @param object contains the javascript object to save, the object must contains an objectID attribute
    #
    def save_object(obj)
      Algolia.client.put(Protocol.object_uri(name, obj["objectID"]), obj.to_json)
    end

    # Override the content of object and wait indexing
    # 
    # @param object contains the javascript object to save, the object must contains an objectID attribute
    #    
    def save_object!(obj)
      res = save_object(obj)
      wait_task(res["taskID"])
      return res
    end

    # Override the content of several objects
    # 
    # @param object contains the javascript object to save, the object must contains an objectID attribute
    #
    def save_objects(objs)
        requests = []
        objs.each do |obj|
            requests.push({"action" => "updateObject", "objectID" => obj["objectID"], "body" => obj})
        end
        request = {"requests" => requests};
        Algolia.client.post(Protocol.batch_uri(name), request.to_json)
    end

    # Override the content of several objects and wait indexing
    # 
    # @param object contains the javascript object to save, the object must contains an objectID attribute
    #    
    def save_objects!(objs)
      res = save_objects(objs)
      wait_task(res["taskID"])
      return res
    end

    #
    # Update partially an object (only update attributes passed in argument)
    # 
    # @param obj contains the javascript attributes to override, the 
    #  object must contains an objectID attribute
    #
    def partial_update_object(obj)
      Algolia.client.post(Protocol.partial_object_uri(name, obj["objectID"]), obj.to_json)
    end
    
    #
    # Update partially an object (only update attributes passed in argument) and wait indexing
    # 
    # @param obj contains the javascript attributes to override, the 
    #  object must contains an objectID attribute
    #
    def partial_update_object!(obj)
      res = partial_update_object(obj)
      wait_task(res["taskID"])
      return res
    end
    
    #
    # Delete an object from the index 
    # 
    # @param objectID the unique identifier of object to delete
    #
    def delete_object(objectID)
      Algolia.client.delete(Protocol.object_uri(name, objectID))
    end
    
    #
    # Set settings for this index
    # 
    # @param settigns the settings object that can contains :
    #  - minWordSizeForApprox1 (integer) the minimum number of characters to accept one typo (default = 3)
    #  - minWordSizeForApprox2: (integer) the minimum number of characters to accept two typos (default = 7)
    #  - hitsPerPage: (integer) the number of hits per page (default = 10)
    #  - attributesToRetrieve: (array of strings) default list of attributes to retrieve for objects
    #  - attributesToHighlight: (array of strings) default list of attributes to highlight
    #  - attributesToIndex: (array of strings) the list of fields you want to index. 
    #    By default all textual attributes of your objects are indexed, but you should update it to get optimal 
    #    results. This parameter has two important uses:
    #       - Limit the attributes to index. 
    #         For example if you store a binary image in base64, you want to store it in the index but you 
    #         don't want to use the base64 string for search.
    #       - Control part of the ranking (see the ranking parameter for full explanation). 
    #         Matches in attributes at the beginning of the list will be considered more important than matches 
    #         in attributes further down the list.
    #  - ranking: (array of strings) controls the way results are sorted. 
    #     We have four available criteria: 
    #       - typo (sort according to number of typos), 
    #       - geo: (sort according to decreassing distance when performing a geo-location based search),
    #       - position (sort according to the matching attribute), 
    #       - custom which is user defined
    #     (the standard order is ["typo", "geo", position", "custom"])
    #  - customRanking: (array of strings) lets you specify part of the ranking. 
    #    The syntax of this condition is an array of strings containing attributes prefixed 
    #    by asc (ascending order) or desc (descending order) operator.
    #
    def set_settings(new_settings)
      Algolia.client.put(Protocol.settings_uri(name), new_settings.to_json)
    end
    
    # Get settings of this index
    def get_settings
      Algolia.client.get(Protocol.settings_uri(name))
    end 
  end
end