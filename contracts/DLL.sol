pragma solidity 0.5.0;

/**
 * @title DLL
 * @notice Library with basic functionalities of double linked list.
 * @author Anibal Catalán <anibalcatalanf@gmail.com>.
 *
 * Originally base on code by skmgoldin
 * https://gist.github.com/skmgoldin/74ce9932893ca3918d0a218c711517b5
 */

library DLL {
    struct Node {
        uint256 next;
        uint256 prev;
    }
    
    struct Data {
        uint256 first;
        uint256 last;
        uint256 count;
        mapping(uint256 => Node) dll;
    }
    
    /**
     * @notice Insert node to the list.
     * @param self struct defined in the contract that is using this library.
     * @param prev previus node.
     * @param curr current node.
     * @param next next node.
     */
    function insert(Data storage self, uint256 prev, uint256 curr, uint256 next) public {
        self.dll[curr].prev = prev;
        self.dll[curr].next = next;
        
        self.dll[prev].next = curr;
        self.dll[next].prev = curr;

        if (prev == 0) {
            self.first = curr;
        }

        if (next == 0) {
            self.last = curr;
        }

        self.count = self.count + 1;
    }
    
    /**
     * @notice Remove node from the list.
     * @param self struct defined in the contract that is using this library.
     * @param curr current node.
     */
    function remove(Data storage self, uint256 curr) public {
        require(self.count > 0, "empty list");
        uint256 next = getNext(self, curr);
        uint256 prev = getPrev(self, curr);
        
        self.dll[next].prev = prev;
        self.dll[prev].next = next;
        
        self.dll[curr].next = curr;
        self.dll[curr].prev = curr;
        
        if (prev == 0) {
            self.first = next;
        }

        if (next == 0) {
            self.last = prev;
        }

        self.count = self.count - 1;
    }
    
    /**
     * @notice Return next node.
     * @param self struct defined in the contract that is using this library.
     * @param curr current node.
     * @return node identifier.
     */
    function getNext(Data storage self, uint256 curr) public view returns (uint256) {
        return self.dll[curr].next;
    }
    
    /**
     * @notice Return previus node.
     * @param self struct defined in the contract that is using this library.
     * @param curr current node.
     * @return node identifier. 
     */
    function getPrev(Data storage self, uint256 curr) public view returns (uint256) {
        return self.dll[curr].prev;
    }
}
