/**
* @author: Carl Judge
* @date: 22-Jun-20
* @description: 
**/

public class Utils {
    /*
        Encodes a string as base64Url
        see https://base64.guru/standards/base64url
     */
    public static String base64UrlEncode(Blob b) {
        return EncodingUtil.base64Encode(b)
            .substringBefore('=')
            .replace('+','-')
            .replace('/','_');
    }
    public static String base64UrlEncode(String s) {
        return base64UrlEncode(Blob.valueOf(s));
    }

    /* because we cant do:
        String name = record.get('parentId__r.Name');
        Instead:
        getCrossObjectField(record, 'parentId__r.Name');
     */
    public static Object getCrossObjectField(SObject rec, String fieldPath) {
        return getValueFromSplitFieldPath(rec, fieldPath.split('\\.'));
    }

    public static Object getValueFromSplitFieldPath(SObject currentSObject, List<String> splitFieldPath) {
        if (currentSObject == null) {
            return null;
        } else if (splitFieldPath.size() == 1) {
            return currentSObject.get(splitFieldPath[0]);
        } else {
            String nextSObjectName = splitFieldPath.remove(0);
            SObject nextSObject = currentSObject.getSObject(nextSObjectName);
            return getValueFromSplitFieldPath(nextSObject, splitFieldPath);
        }
    }
}