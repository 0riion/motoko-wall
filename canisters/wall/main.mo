import Principal "mo:base/Principal";
import Int "mo:base/Int";
import Blob "mo:base/Blob";
import Text "mo:base/Text";
import HashMap "mo:base/HashMap";
import Nat "mo:base/Nat";
import Hash "mo:base/Hash";
import Result "mo:base/Result";
import Buffer "mo:base/Buffer";
import Iter "mo:base/Iter";
import Array "mo:base/Array";
import Bool "mo:base/Bool";

actor {

    var currentMessageId : Nat = 0;

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

    private func _isOwnerCaller(caller : Principal, owner : Principal) : Bool {
        return caller == owner
    };

    private func _getIncreasedMessage(message : Message) : Message {
        return {
            creator = message.creator;
            content = message.content;
            vote = message.vote + 1
        }
    };

    private func _getDecreasedMessage(message : Message) : Message {
        return {
            creator = message.creator;
            content = message.content;
            vote = message.vote - 1
        }
    };

    public shared ({ caller }) func writeMessage(content : Content) : async Nat {
        let id : Nat = currentMessageId;
        currentMessageId += 1;

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

    public shared ({ caller }) func updateMessage(messageId : Nat, content : Content) : async Result.Result<(), Text> {
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
                if (not _isOwnerCaller(message.creator, caller)) {
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
                if (not _isOwnerCaller(message.creator, caller)) {
                    return #err "You are not the creator of this message!"
                };

                ignore wall.remove(messageId);
                return #ok()
            }
        }
    };

    public func getAllMessages() : async [Message] {
        let messagesBuff = Buffer.Buffer<Message>(0);

        for (message in wall.vals()) {
            messagesBuff.add(message)
        };

        var messages = Buffer.toVarArray<Message>(messagesBuff);
        var size = messages.size();

        if (size > 0) {
            size -= 1
        };

        for (index in Iter.range(0, size)) {
            var maxIndex = index;

            for (subIndex in Iter.range(0, size)) {

                if (messages[subIndex].vote > messages[index].vote) {
                    maxIndex := subIndex
                }
            };

            let temp = messages[index];
            messages[maxIndex] := messages[index];
            messages[index] := temp
        };

        return Array.freeze<Message>(messages)
    };

    // votting methods

    public func voteUp(messageId : Nat) : async Result.Result<(), Text> {
        let messageData : ?Message = wall.get(messageId);

        switch (messageData) {
            case (null) {
                return #err "the requested message does not exist."
            };

            case (?message) {
                let updatedMessage : Message = _getIncreasedMessage(message);

                wall.put(messageId, updatedMessage);

                return #ok()
            }
        };

        return #ok()
    };

    public func voteDown(messageId : Nat) : async Result.Result<(), Text> {
        let messageData : ?Message = wall.get(messageId);

        switch (messageData) {
            case (null) {
                return #err "The message you are looking for, does not exist!"
            };
            case (?message) {
                let updatedMessage : Message = _getDecreasedMessage(message);
                wall.put(messageId, updatedMessage);

                return #ok()
            }
        };

        return #ok()
    };

}
