import Principal "mo:base/Principal";
import Int "mo:base/Int";
import Blob "mo:base/Blob";
import Text "mo:base/Text";
import HashMap "mo:base/HashMap";
import Nat "mo:base/Nat";
import Hash "mo:base/Hash";
import Result "mo:base/Result";

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

    public shared query func getMessage(messageId : Nat) : async Result.Result<Message, Text> {
        let messageData : ?Message = wall.get(messageId);

        switch (messageData) {
            case (null) {
                return #err "The requred message does not exist."
            };
            case (?message) {
                return #ok message
            }
        }
    };

    public shared ({ caller }) func updateMessage(message : Nat, content : Content) : async Result.Result<(), Text> {
        var isAuth : Bool = not Principal.isAnonymous(caller);
        if (not isAuth) {
            return #err "You must eb authenticated to validate that you are the creator of the message!"
        };

        let messageData : ?Message = wall.get(messageId);

        switch (messageData) {
            case (null) {
                return #err "The requested message does not exist."
            };
            case (?message) {
                if (message.creator != caller) {
                    return #err "You are not the creator of this message!"
                };

                let updatedMessage : Message = {
                    creator = message.creator;
                    content = content;
                    vote = message.vote
                };

                wall.put(messageId, updatedMessage);

                return #ok()
            }
        }
    };

    public shared ({ caller }) func deleteMessage(messageId : Nat) : async Result.Result<(), Text> {
        let messageData : ?Message = wall.get(messageId);

        switch (messageData) {
            case (null) {
                return #err "the requested message does not exist."
            };
            case (?message) {
                if (message.creator != caller) {
                    return #err "You are not the creator of this message!"
                };

                ignore wall.remove(messageId);
                return #ok()
            }
        }
    };

}
