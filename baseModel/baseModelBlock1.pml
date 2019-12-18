inline canApassB(A, B, passFlag){
    atomic {
        // can A directly pass B
        // if intersection of union(RCL[A] and IDofA) and union(ACL[B], GCL[B], SCL[B]) is not empty, pass, passFlag = true
        // else, can not pass, passFlag = false
        passFlag = false;
        
        short indexA = 0;
        short indexBACL = 0;
        short indexBGCL = 0;
        short indexBSCL = 0;
        short IDofA = A + 1;
        do
            :: indexA < RCLs[A].index ->
            
                indexBACL = 0;
                do
                    :: indexBACL < ACLs[B].index ->
                        if
                            :: ACLs[B].credentialArray[indexBACL] == RCLs[A].credentialArray[indexA] || ACLs[B].credentialArray[indexBACL] == IDofA ->
                                passFlag = true;
                                goto endofcanApassB;
                            :: else ->
                                skip;
                        fi;
                        indexBACL ++;
                    :: else -> 
                        break;
                od;
                
                indexBGCL = 0;
                do
                    :: indexBGCL < GCLs[B].index ->
                        if
                            :: GCLs[B].credentialArray[indexBGCL] == RCLs[A].credentialArray[indexA] || ACLs[B].credentialArray[indexBACL] == IDofA ->
                                passFlag = true;
                                goto endofcanApassB;
                            :: else ->
                                skip;
                        fi;
                        indexBGCL ++;
                    :: else -> 
                        break;
                od;
                
                indexBSCL = 0;
                do
                    :: indexBSCL < SCLs[B].index ->
                        if
                            :: SCLs[B].credentialArray[indexBSCL] == RCLs[A].credentialArray[indexA] || ACLs[B].credentialArray[indexBACL] == IDofA ->
                                passFlag = true;
                                goto endofcanApassB;
                            :: else ->
                                skip;
                        fi;
                        indexBSCL ++;
                    :: else -> 
                        break;
                od;
                
                indexA ++;
            :: else ->
                break;
        od;
        
        endofcanApassB: 
            skip;
    }
}

inline setLineinadjacencyMatrix(whoisA){
    atomic {
        // can A directly pass B
        short whoisB = 0;
        do
            :: whoisB < MAXENITYNUM ->
                if  
                    :: whoisB == whoisA ->
                        adjacencyMatrix[whoisA].order1[whoisB] = true;
                    :: else ->
                        canApassB(whoisA, whoisB, adjacencyMatrix[whoisA].order1[whoisB]);
                fi;
                whoisB ++;
            :: else -> 
                break;
        od;
    }
}

inline calAdjacencyMatrix(){
    atomic {
        // erase the adjacencyMatrix
        short indexadjMatrixOrder1 = 0;
        short indexadjMatrixOrder2 = 0;
        do
            :: indexadjMatrixOrder2 < MAXENITYNUM ->
                indexadjMatrixOrder1 = 0;
                do
                    :: indexadjMatrixOrder1 < MAXENITYNUM ->
                        if 
                            :: indexadjMatrixOrder2 == indexadjMatrixOrder1 ->
                                adjacencyMatrix[indexadjMatrixOrder2].order1[indexadjMatrixOrder1] = true;
                            :: else ->
                                adjacencyMatrix[indexadjMatrixOrder2].order1[indexadjMatrixOrder1] = false;
                        fi;
                        indexadjMatrixOrder1 ++;
                    :: else ->
                        break;
                od;
                indexadjMatrixOrder2 ++;
            :: else ->
                break;
        od;

        short indexCalAdjMatrix = 0;
            do
                :: indexCalAdjMatrix < MAXENITYNUM ->
                   setLineinadjacencyMatrix(indexCalAdjMatrix);
                   indexCalAdjMatrix ++;
                :: else ->
                    break;
            od;
    }
}

inline setLineinreachabilityMatrix(RchMatrixwhoisA){
    atomic {
        // set Line of RchMatrixwhoisA in reachabilityMatrix

        array2 canReachEntities;
        short indexcanReachEntities = 0;
        short indexRchMatrixwhoisA = 0;
        
        bool inFlag = false;

        // erase the canReachEntities
        canReachEntities.index = 0;
        indexcanReachEntities = 0;
        do
            :: indexcanReachEntities < MAXENITYNUM ->
                canReachEntities.entities[indexcanReachEntities] = -1; // can erase to 0, because DEVICE == 0
                indexcanReachEntities ++;
            :: else ->
                break;
        od;

        // put RchMatrixwhoisA's conneted nodes in the set
        indexRchMatrixwhoisA = 0;
        do
            :: indexRchMatrixwhoisA < MAXENITYNUM ->
                if 
                :: adjacencyMatrix[RchMatrixwhoisA].order1[indexRchMatrixwhoisA] == true ->
                    addItemArray2(canReachEntities, indexRchMatrixwhoisA);
                :: else ->
                    skip;
                fi;
                indexRchMatrixwhoisA ++;
            :: else ->
                break;
        od;
        
        // travel all the nodes in canReachEntities, to add other not-directly connected nodes
        indexcanReachEntities = 0;
        do
            :: indexcanReachEntities < canReachEntities.index ->
                
                if 
                :: canReachEntities.entities[indexcanReachEntities] != RchMatrixwhoisA ->
                    // add the connected nodes of the connected nodes, if it not already in
                    indexRchMatrixwhoisA = 0;
                    do
                        :: indexRchMatrixwhoisA < MAXENITYNUM ->
                        if
                            :: adjacencyMatrix[canReachEntities.entities[indexcanReachEntities]].order1[indexRchMatrixwhoisA] == true ->
                                // is it already in canReachEntities? not in, add 
                                isIteminArray2(indexRchMatrixwhoisA, canReachEntities, inFlag);
                                if
                                :: inFlag == false -> // not in, add to canReachEntities
                                    addItemArray2(canReachEntities, indexRchMatrixwhoisA);
                                :: else ->
                                    skip;
                                fi;
                            :: else ->
                                skip;
                        fi;
                        indexRchMatrixwhoisA ++;
                        :: else ->
                        break;
                    od;
                    
                :: else ->
                    skip;
                fi;
                
                indexcanReachEntities ++;
            :: else ->
                break;
        od;

        // now all reachable nodes are recorded in canReachEntities 
        // travel the canReachEntities again, to set the reachabilityMatrix
         indexcanReachEntities = 0;
        do
            :: indexcanReachEntities < canReachEntities.index ->
                reachabilityMatrix[RchMatrixwhoisA].order1[canReachEntities.entities[indexcanReachEntities]] = true;
                indexcanReachEntities ++;
            :: else ->
                break;
        od;
    }
}

inline calreachabilityMatrix(){
    atomic {
        // erase the reachabilityMatrix
        short indexreachMatrixOrder1 = 0;
        short indexreachMatrixOrder2 = 0;
        do
            :: indexreachMatrixOrder2 < MAXENITYNUM ->
                indexreachMatrixOrder1 = 0;
                do
                    :: indexreachMatrixOrder1 < MAXENITYNUM ->
                        if 
                            :: indexreachMatrixOrder2 == indexreachMatrixOrder1 ->
                                reachabilityMatrix[indexreachMatrixOrder2].order1[indexreachMatrixOrder1] = true;
                            :: else ->
                                reachabilityMatrix[indexreachMatrixOrder2].order1[indexreachMatrixOrder1] = false;
                        fi;
                        indexreachMatrixOrder1 ++;
                    :: else ->
                        break;
                od;
                indexreachMatrixOrder2 ++;
            :: else ->
                break;
        od;
    
    
        short indexCalReachMatrix = 0;
        calAdjacencyMatrix();
        do
            :: indexCalReachMatrix < MAXENITYNUM ->
                setLineinreachabilityMatrix(indexCalReachMatrix);
                indexCalReachMatrix ++;
            :: else ->
                break;
        od;
        
    }
}

inline addSCLstoRCLs(fromWhoseSCL, toWhoseRCL){
    atomic {
        short indexaddSCLstoRCLs = 0;
        bool isinflagaddSCLstoRCLs = false;
        do
            :: indexaddSCLstoRCLs < SCLs[fromWhoseSCL].index ->
                isIteminArray(SCLs[fromWhoseSCL].credentialArray[indexaddSCLstoRCLs], RCLs[toWhoseRCL], isinflagaddSCLstoRCLs);
                if :: isinflagaddSCLstoRCLs == false ->
                        addItemRCL(toWhoseRCL, SCLs[fromWhoseSCL].credentialArray[indexaddSCLstoRCLs]);
                   :: else ->
                        skip;
                fi;
                indexaddSCLstoRCLs ++;
            :: else ->
                break;
        od;
    }
}

inline addGCLstoRCLs(fromWhoseGCL, toWhORCL){
    atomic {
        short indexaddGCLstoRCLs = 0;
        bool isinflagaddGCLstoRCLs = false;
        do
            :: indexaddGCLstoRCLs < GCLs[fromWhoseGCL].index ->
                isIteminArray(GCLs[fromWhoseGCL].credentialArray[indexaddGCLstoRCLs], RCLs[toWhORCL], isinflagaddGCLstoRCLs);
                if :: isinflagaddGCLstoRCLs == false ->
                        addItemRCL(toWhORCL, GCLs[fromWhoseGCL].credentialArray[indexaddGCLstoRCLs]);
                   :: else ->
                        skip;
                fi;
                indexaddGCLstoRCLs ++;
            :: else ->
                break;
        od;
    }
}

inline isIteminArray(item, isinarray, flag){
    atomic {
        short indexisIteminArray = 0;
        flag = false;
        do
            :: indexisIteminArray < isinarray.index ->
                if 
                    :: isinarray.credentialArray[indexisIteminArray] == item ->
                        flag = true;
                        break;
                    :: else ->
                        indexisIteminArray ++;
                fi;
            :: else ->
                break;
        od;
    }
}

inline isIteminArray2(item2, isinarray2, flag2){
    atomic {
        short indexisIteminArray = 0;
        flag2 = false;
        do
            :: indexisIteminArray < isinarray2.index ->
                if 
                    :: isinarray2.entities[indexisIteminArray] == item2 ->
                        flag2 = true;
                        break;
                    :: else ->
                        indexisIteminArray ++;
                fi;
            :: else ->
                break;
        od;
    }
}

inline addItemArray2(whicharray, whichItem){
    atomic {
        if
            :: whicharray.index >= MAXENITYNUM ->
                printf("Exceed MAXENITYNUM when adding item in addItemArray2 \n"); 
            :: else ->
                whicharray.entities[whicharray.index] = whichItem;
                whicharray.index ++;
        fi;
    }
}

inline addItemACL(who, item){
    atomic {
        if
            :: who >= MAXENITYNUM || who < 0 ->
                printf("wrong parameter in addItemACL: wrong value of who: %d", who);
                myOwnErrorFlag = true;
            :: ACLs[who].index >= MAXCREDENTIALNUM -> 
                printf("Exceed MAXCREDENTIALNUM when adding item in ACLs[%d] \n", who); 
                myOwnErrorFlag = true;
            :: else -> 
                ACLs[who].credentialArray[ACLs[who].index] = item;
                ACLs[who].index ++;
        fi;
    }
}

inline addItemRCL(who, item){
    atomic {
        if
            :: who >= MAXENITYNUM || who < 0 ->
                printf("wrong parameter in addItemRCL: wrong value of who: %d", who);
                myOwnErrorFlag = true;
            :: RCLs[who].index >= MAXCREDENTIALNUM -> 
                printf("Exceed MAXCREDENTIALNUM when adding item (%d) in RCLs[%d] \n", item, who); 
                myOwnErrorFlag = true;
            :: else -> 
                RCLs[who].credentialArray[RCLs[who].index] = item;
                RCLs[who].index ++;
        fi;
    }
}

inline addItemSCL(who, item){
    atomic {
        if
            :: who >= MAXENITYNUM || who < 0 ->
                printf("wrong parameter in addItemSCL: wrong value of who: %d", who);
                myOwnErrorFlag = true;
            :: SCLs[who].index >= MAXCREDENTIALNUM -> 
                printf("Exceed MAXCREDENTIALNUM when adding item in SCLs[%d] \n", who); 
                myOwnErrorFlag = true;
            :: else -> 
                SCLs[who].credentialArray[SCLs[who].index] = item;
                SCLs[who].index ++;
        fi;
    }
}

inline addItemGCL(delegator, delegatee, item){
    atomic {
        if
            :: delegator >= MAXENITYNUM || delegator < 0 ->
                printf("wrong parameter in addItemGCL: wrong value of delegator: %d", delegator);
                myOwnErrorFlag = true;
            :: delegatee >= MAXENITYNUM || delegatee < 0 ->
                printf("wrong parameter in addItemGCL: wrong value of delegatee: %d", delegatee);
                myOwnErrorFlag = true;
            :: GCLs[delegator].index >= MAXCREDENTIALNUM -> 
                printf("Exceed MAXCREDENTIALNUM when adding item in GCLs[%d] \n", delegator); 
                myOwnErrorFlag = true;
            :: else -> 
                GCLs[delegator].credentialArray[GCLs[delegator].index] = item;
                GCLs[delegator].delegateeArray[GCLs[delegator].index] = delegatee;
                GCLs[delegator].index ++;
        fi;
    }
}

inline removeItemACL(who, item){
    atomic {
        short indexRmvACLSearch = 0;
        short indexRmvACLAdd = 0;
        short swapACL = 0;
        
        if 
            :: !(who >= MAXENITYNUM || who < 0 || item > MAXENITYNUM || item < 0) ->
                do
                    :: indexRmvACLSearch < ACLs[who].index ->
                        swapACL = ACLs[who].credentialArray[indexRmvACLSearch];
                        ACLs[who].credentialArray[indexRmvACLSearch] = 0;
                        if 
                            :: swapACL != item ->
                                ACLs[who].credentialArray[indexRmvACLAdd] = swapACL;
                                indexRmvACLAdd ++;
                            :: else ->
                                skip;
                        fi;
                        indexRmvACLSearch ++;
                    :: else -> 
                        ACLs[who].index = indexRmvACLAdd;
                        break;
                od;
            :: else ->
                printf("wrong parameter in removeItemACL: who is %d, item is %d \n", who, item);
                myOwnErrorFlag = true;
        fi;
    }
}

inline removeItemRCL(who, item){
    atomic {
        short indexRmvRCLSearch = 0;
        short indexRmvRCLAdd = 0;
        short swapRCL = 0;
        
        if 
            :: !(who >= MAXENITYNUM || who < 0 || item > MAXENITYNUM || item < 0) ->
                do
                    :: indexRmvRCLSearch < RCLs[who].index ->
                        swapRCL = RCLs[who].credentialArray[indexRmvRCLSearch];
                        RCLs[who].credentialArray[indexRmvRCLSearch] = 0;
                        if 
                            :: swapRCL != item ->
                                RCLs[who].credentialArray[indexRmvRCLAdd] = swapRCL;
                                indexRmvRCLAdd ++;
                            :: else ->
                                skip;
                        fi;
                        indexRmvRCLSearch ++;
                    :: else -> 
                        RCLs[who].index = indexRmvRCLAdd;
                        break;
                od;
            :: else ->
                printf("wrong parameter in removeItemRCL: who is %d, item is %d \n", who, item);
                myOwnErrorFlag = true;
        fi;
    }
}

inline removeItemGCL(delegator, delegatee){
    atomic {
        short indexRmvGCLSearch = 0;
        short indexRmvGCLAdd = 0;
        short swapGCLCredential = 0;
        short swapGCLDelegatee = 0;
        
        if
            ::  !(delegator >= MAXENITYNUM || delegator < 0 || delegatee >= MAXENITYNUM || delegatee < 0) ->
                do
                    :: indexRmvGCLSearch < GCLs[delegator].index ->
                        swapGCLCredential = GCLs[delegator].credentialArray[indexRmvGCLSearch];
                        swapGCLDelegatee = GCLs[delegator].delegateeArray[indexRmvGCLSearch];
                        GCLs[delegator].credentialArray[indexRmvGCLSearch] = 0;
                        GCLs[delegator].delegateeArray[indexRmvGCLSearch] = 0;
                        if 
                            :: swapGCLDelegatee != delegatee ->
                                GCLs[delegator].credentialArray[indexRmvGCLAdd] = swapGCLCredential;
                                GCLs[delegator].delegateeArray[indexRmvGCLAdd] = swapGCLDelegatee;
                                indexRmvGCLAdd ++;
                            :: else ->
                                skip;
                        fi;
                        indexRmvGCLSearch ++;
                    :: else ->
                        GCLs[delegator].index = indexRmvGCLAdd;
                        break;
                od;
            :: else ->
                printf("wrong parameter in removeItemGCL: delegator is %d, delegatee is %d \n", delegator, delegatee);
                myOwnErrorFlag = true;
        fi;
    }
}

inline removeAllItemsGCL(targetDelegator){
    atomic{
        short indexsearchAllGCL = 0;
        do
            :: indexsearchAllGCL < GCLs[targetDelegator].index ->
                GCLs[targetDelegator].credentialArray[indexsearchAllGCL] = 0;
                GCLs[targetDelegator].delegateeArray[indexsearchAllGCL] = 0;
                indexsearchAllGCL ++;
            :: else ->
                GCLs[targetDelegator].index = 0;
        od;
    }
}

inline addRCLstoRCLs(fromWhom, toWhom){
    atomic {
        short indexaddRCLstoRCLs = 0;
        bool isinflagaddRCLstoRCLs = false;
        do
            :: indexaddRCLstoRCLs < RCLs[fromWhom].index ->
                isIteminArray(RCLs[fromWhom].credentialArray[indexaddRCLstoRCLs], RCLs[toWhom], isinflagaddRCLstoRCLs);
                if :: isinflagaddRCLstoRCLs == false ->
                        addItemRCL(toWhom, RCLs[fromWhom].credentialArray[indexaddRCLstoRCLs]);
                   :: else ->
                        skip;
                fi;
                indexaddRCLstoRCLs ++;
            :: else ->
                break;
        od;
    }
}