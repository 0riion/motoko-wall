import Principal "mo:base/Principal";
import Int "mo:base/Int";
import Blob "mo:base/Blob";
import Text "mo:base/Text";
actor {
    public type Content = {
        #Text : Text;
        #Image : Blob;
        #Video : Blob
    };

    type Message = {
        vote : Int;
        content : Content;
        creator : Principal;
    }
}
