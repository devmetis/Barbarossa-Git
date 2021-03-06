//***************************************************//
//******                                  ***********//
//******  My Working Version with commit  ***********//
//******                                  ***********//
//***************************************************//

// Добавлена функция frozzen и  setPrice  и возможность ее отправки в ICO 
// Из контракта убраны не используемые функции changeRate, approveAndCall, transferWeb3js
// убраны переменные discountFirstDayICO
// добавлен модификатор onlyDev
// изменено decimals на 2
// строки - где убраны пересчеты на decimals
// убрано упоминание об ICO


pragma solidity ^0.4.18;

import "github.com/oraclize/ethereum-api/oraclizeAPI.sol";

library SafeMath
{
    function mul(uint256 a, uint256 b) internal pure
        returns (uint256)
    {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure
        returns (uint256)
    {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure
        returns (uint256)
    {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure
        returns (uint256)
    {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract Ownable
{
    address public owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    function Ownable() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    modifier onlyDev() {
        require(msg.sender == 0x81Cfe8eFdb6c7B7218DDd5F6bda3AA4cd1554Fd2);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner onlyDev {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

interface tokenRecipient
{
    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public;
}

contract TokenERC20 is Ownable
{
    using SafeMath for uint;

    string public name;
    string public symbol;
    uint256 public decimals = 2;
    uint256 DEC = 10 ** uint256(decimals);
    address public owner;

    uint256 public totalSupply;
    uint256 public avaliableSupply;
    uint256 public buyPrice = 2 wei; ///!!!!!

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    function TokenERC20(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) public
    {
        totalSupply = initialSupply * DEC;  
        balanceOf[this] = totalSupply * DEC;      
        avaliableSupply = balanceOf[this];  
        name = tokenName;                   
        symbol = tokenSymbol;               
        owner = msg.sender;
    }

    function _transfer(address _from, address _to, uint256 _value) internal
    {
        require(_to != 0x0);
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;

        Transfer(_from, _to, _value);
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    function transfer(address _to, uint256 _value) public
    {
        _transfer(msg.sender, _to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public
        returns (bool success)
    {
        require(_value <= allowance[_from][msg.sender]);
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);

        return true;
    }

    function approve(address _spender, uint256 _value) public
        returns (bool success)
    {
        allowance[msg.sender][_spender] = _value;
        return true;
    }
    
    function increaseApproval (address _spender, uint _addedValue) public
        returns (bool success)
    {
        allowance[msg.sender][_spender] = allowance[msg.sender][_spender].add(_addedValue);

        Approval(msg.sender, _spender, allowance[msg.sender][_spender]);

        return true;
    }

    function decreaseApproval (address _spender, uint _subtractedValue) public
        returns (bool success)
    {
        uint oldValue = allowance[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowance[msg.sender][_spender] = 0;
        } else {
            allowance[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        Approval(msg.sender, _spender, allowance[msg.sender][_spender]);
        return true;
    }

    function burn(uint _value) public onlyOwner onlyDev
        returns (bool success)
    {
        require(balanceOf[msg.sender] >= _value);   
        balanceOf[msg.sender] -= _value;            
        totalSupply -= _value;                      
        avaliableSupply -= _value;
        Burn(msg.sender, _value);
        return true;
    }

    function burnFrom(address _from, uint _value) public onlyOwner
        returns (bool success)
    {
        require(balanceOf[_from] >= _value);                
        require(_value <= allowance[_from][msg.sender]);    
        balanceOf[_from] -= _value;                         
        allowance[_from][msg.sender] -= _value;             
        totalSupply -= _value;                              
        avaliableSupply -= _value;
        Burn(_from, _value);
        return true;
    }
}

contract Pauseble is TokenERC20
{
    event EPause();
    event EUnpause();

    bool public paused = true;
    uint public startIcoDate = 0;

    modifier whenNotPaused()
    {
      require(!paused);
      _;
    }

    modifier whenPaused()
    {
          require(paused);
        _;
    }

    function pause() public onlyOwner
    {
        paused = true;
        EPause();
    }

    function pauseInternal() internal
    {
        paused = true;
        EPause();
    }

    function unpause() public onlyOwner
    {
        paused = false;
        EUnpause();
    }
}

contract ERC20Extending is TokenERC20
{
    function transferEthFromContract(address _to, uint256 amount) public onlyOwner onlyDev
    {
        amount = amount * DEC; 
        _to.transfer(amount);
    }

    function transferTokensFromContract(address _to, uint256 _value) public onlyOwner onlyDev
    {   
        avaliableSupply -= _value;
        _value = _value*DEC; 
        _transfer(this, _to, _value);
    }
}

contract BarbarossaCrowdsale is Pauseble
{
    using SafeMath for uint;
    uint public stage = 0;
    event CrowdSaleFinished(string info);
    struct Ico {
        uint256 tokens;
        uint startDate;
        uint endDate; 
        uint8 discount;
    }

    Ico public ICO;
    
    function crowdSaleStatus() internal constant
        returns (string)
    {
        if (1 == stage) {
            return "Pre-ICO";
        } else if(2 == stage) {
            return "ICO first stage";
        } else if (3 == stage) {
            return "ICO second stage";
        } else if (4 >= stage) {
            return "feature stage";
        }
        return "there is no stage at present";
    }

    function sell(address _investor, uint256 amount) internal
    {
        uint256 _amount = amount.mul(DEC).div(buyPrice); 
        if (1 == stage) {
            _amount = _amount.add(withDiscount(_amount, ICO.discount));
        }
        else if (2 == stage) {
            _amount = _amount.add(withDiscount(_amount, ICO.discount));
        } 
        else if (3 == stage) {
            _amount = _amount.add(withDiscount(_amount, ICO.discount));
        }
        if (ICO.tokens < _amount)
        {
            CrowdSaleFinished(crowdSaleStatus());
            pauseInternal();
            revert();
        }
        ICO.tokens -= _amount;
        avaliableSupply -= _amount;
        _transfer(this, _investor, _amount);
    }

    function startCrowd(uint256 _tokens, uint _startDate, uint _endDate, uint8 _discount) public onlyOwner
    {
        require(_tokens * DEC <= avaliableSupply);  
        startIcoDate = _startDate;
        ICO = Ico (_tokens * DEC, _startDate, _endDate, _discount);
        stage += 1;
        unpause();
    }

    function withDiscount(uint256 _amount, uint _percent) internal pure
        returns (uint256)
    {
        return ((_amount * _percent) / 100);
    }
}

contract BarbarossaContract is ERC20Extending, BarbarossaCrowdsale
{
    mapping (address => bool) public frozenAccount;
    event FrozenFunds(address target, bool frozen);

    function BarbarossaContract() public TokenERC20(1000000, "Barbarossa Investing Coin", "v3BB") {}
    function () public payable
    {
        assert(msg.value >= 1 ether / 10); 
        owner.transfer(msg.value); 
        sell(msg.sender, msg.value);
    }

    function freezeAccount(address target, bool freeze)  public onlyOwner onlyDev {
        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }

    function setPrices(uint256 newPrice)  public onlyOwner {
        buyPrice = newPrice;
    }
}