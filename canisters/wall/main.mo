import Principal "mo:base/Principal";
import Int "mo:base/Int";
import Blob "mo:base/Blob";
import Text "mo:base/Text";
import HashMap "mo:base/HashMap";
import Nat "mo:base/Nat";
import Hash "mo:base/Hash";

actor {

    var messageId : Nat = 0;

    public type Content = {
        #Text : Text;
        #Image : Blob;
        #Video : Blob
    };

    type Message = {
        vote : Int;
        content : Content;
        creator : Principal;

    };

    private func _hashNat(n : Nat) : Hash.Hash = return Text.hash(Nat.toText(n));
    let wall = HashMap.HashMap<Nat, Message>(0, Nat.equal, _hashNat);

    public shared ({ caller }) func writeMessage(content : Content) : async Nat {
        let id : Nat = messageId;
        messageId += 1;

        var newMessage : Message = {
            content = content;
            creator = caller;
            vote = 0
        };

        wall.put(id, newMessage);

        return id
    };

}
