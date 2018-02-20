//***************************************************//
//******                                  ***********//
//******  My Working Version with commit  ***********//
//******                                  ***********//
//***************************************************//


pragma solidity ^0.4.18;

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
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
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

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract Migrations is Ownable {
  uint256 public lastCompletedMigration;

  function setCompleted(uint256 completed) onlyOwner  public {
    lastCompletedMigration = completed;
  }

  function upgrade(address newAddress) onlyOwner  public {
    Migrations upgraded = Migrations(newAddress);
    upgraded.setCompleted(lastCompletedMigration);
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
    uint256 public decimals = 18;
    uint256 DEC = 10 ** uint256(decimals); //конвертация из wei
    address public owner;

    uint256 public totalSupply;
    uint256 public avaliableSupply;
    uint256 public buyPrice = 12000 szabo; // цена покупки - заменил с 1 эфира на 0.02

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    function TokenERC20(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) public
    {
        totalSupply = initialSupply * DEC;  // Update total supply with the decimal amount
        balanceOf[this] = totalSupply;                // Give the creator all initial tokens
        avaliableSupply = balanceOf[this];            // Show how much tokens on contract
        name = tokenName;                                   // Set the name for display purposes
        symbol = tokenSymbol;                               // Set the symbol for display purposes
        owner = msg.sender;
    }

    function _transfer(address _from, address _to, uint256 _value) internal
    {
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != 0x0);
        // Check if the sender has enough
        require(balanceOf[_from] >= _value);
        // Check for overflows
        require(balanceOf[_to] + _value > balanceOf[_to]);
        // Save this for an assertion in the future
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        // Subtract from the sender
        balanceOf[_from] -= _value;
        // Add the same to the recipient
        balanceOf[_to] += _value;

        Transfer(_from, _to, _value);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    /**
     * Transfer tokens
     *
     * Send `_value` tokens to `_to` from your account
     *
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transfer(address _to, uint256 _value) public
    {
        _transfer(msg.sender, _to, _value);
    }

    /**
     * Transfer tokens from other address
     *
     * Send `_value` tokens to `_to` in behalf of `_from`
     *
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transferFrom(address _from, address _to, uint256 _value) public
        returns (bool success)
    {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance

        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);

        return true;
    }

    /**
     * Set allowance for other address
     *
     * Allows `_spender` to spend no more than `_value` tokens in your behalf
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     */
    function approve(address _spender, uint256 _value) public
        returns (bool success)
    {
        allowance[msg.sender][_spender] = _value;
        return true;
    }
    /**
     * Set allowance for other address and notify
     *
     * Allows `_spender` to spend no more than `_value` tokens in your behalf, and then ping the contract about it
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     * @param _extraData some extra information to send to the approved contract
     */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public onlyOwner
        returns (bool success)
    {
        tokenRecipient spender = tokenRecipient(_spender);

        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }
    /**
     * approve should be called when allowed[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     */
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
    /**
     * Destroy tokens
     *
     * Remove `_value` tokens from the system irreversibly
     *
     * @param _value the amount of money to burn
     */
    function burn(uint256 _value) public onlyOwner
        returns (bool success)
    {
        require(balanceOf[msg.sender] >= _value);   // Check if the sender has enough
        balanceOf[msg.sender] -= _value;            // Subtract from the sender
        totalSupply -= _value;                      // Updates totalSupply
        avaliableSupply -= _value;
        Burn(msg.sender, _value);
        return true;
    }
    /**
     * Destroy tokens from other account
     *
     * Remove `_value` tokens from the system irreversibly on behalf of `_from`.
     *
     * @param _from the address of the sender
     * @param _value the amount of money to burn
     */
    function burnFrom(address _from, uint256 _value) public onlyOwner
        returns (bool success)
    {
        require(balanceOf[_from] >= _value);                // Check if the targeted balance is enough
        require(_value <= allowance[_from][msg.sender]);    // Check allowance
        balanceOf[_from] -= _value;                         // Subtract from the targeted balance
        allowance[_from][msg.sender] -= _value;             // Subtract from the sender's allowance
        totalSupply -= _value;                              // Update totalSupply
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
    /**
    * Function for transfer ethereum from contract to any address
    *
    * @param _to - address of the recipient
    * @param amount - ethereum
    */
    function transferEthFromContract(address _to, uint256 amount) public onlyOwner
    {
        amount = amount * DEC; //пытаюсь решить проблемы с нулями - при тестировании в Remix работате корректно
        _to.transfer(amount);
    }

    /**
    * Function for transfer tokens from contract to any address
    *
    */
    function transferTokensFromContract(address _to, uint256 _value) public onlyOwner
    {   
        avaliableSupply -= _value;
        _value = _value*DEC; //пытаюсь решить проблемы с нулями
        _transfer(this, _to, _value);
    }
}

contract BarbarossaCrowdsale is Pauseble
{
    using SafeMath for uint;

    uint public stage = 0;

    event CrowdSaleFinished(string info);

    struct Ico {
        uint256 tokens; // Tokens in crowdsale
        uint startDate; // Дата, когда crowdsale будет запускаться, после его запуска это свойство будет 0
        uint endDate; // Date when crowdsale will be stop
        uint8 discount; // Discount
        uint8 discountFirstDayICO; // Discount. Only for first stage ico
    }

    Ico public ICO;

    /**
    * Expanding of the functionality
    *
    * @param _numerator - Numerator - value (10000)
    * @param _denominator - Denominator - value (10000)
    *
    * example: price 1000 tokens by 1 ether = changeRate(1, 1000)
    */
    function changeRate(uint256 _numerator, uint256 _denominator) public onlyOwner
        returns (bool success)
    {
        if (_numerator == 0) _numerator = 1;
        if (_denominator == 0) _denominator = 1;

        buyPrice = (_numerator * 1 * DEC) / _denominator;

        return true;
    }

    /*
    * Function show in contract what is now
    *
    */
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

    /*
    * Function for selling tokens in crowd time.
    *
    */
    function sell(address _investor, uint256 amount) internal
    {
        ///uint256 _amount = (amount / buyPrice) * DEC;
        uint256 _amount = amount.mul(DEC).div(buyPrice); /// данная строка вызывает ошибку при переислении менее 1 эфира - возникает дробная часть, в solidity не предусмотреннная - предлагаю заменить на  - uint256 _amount = amount.mul(DEC).div(buyPrice);
        if (1 == stage) {
            _amount = _amount.add(withDiscount(_amount, ICO.discount));
        }
        else if (2 == stage)
        {
            if (now <= ICO.startDate + 1 days)
            {
                  if (0 == ICO.discountFirstDayICO) {
                      ICO.discountFirstDayICO = 20;
                  }
                  _amount = _amount.add(withDiscount(_amount, ICO.discountFirstDayICO));
            } else {
                _amount = _amount.add(withDiscount(_amount, ICO.discount));
            }
        } else if (3 == stage) {
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

    /*
    * Function for start crowdsale (any)
    *
    * @param _tokens - How much tokens will have the crowdsale - amount humanlike value (10000)
    * @param _startDate - When crowdsale will be start - unix timestamp (1512231703 )
    * @param _endDate - When crowdsale will be end - humanlike value (7) same as 7 days
    * @param _discount - Discount for the crowd - humanlive value (7) same as 7 %
    * @param _discount - Discount for the crowds first day - humanlive value (7) same as 7 %
    */
    function startCrowd(uint256 _tokens, uint _startDate, uint _endDate, uint8 _discount, uint8 _discountFirstDayICO) public onlyOwner
    {
        require(_tokens * DEC <= avaliableSupply);  // require to set correct tokens value for crowd
        startIcoDate = _startDate;
        ICO = Ico (_tokens * DEC, _startDate, _endDate, _discount, _discountFirstDayICO);
        stage += 1;
        unpause();
    }

    /**
    * Function for web3js, should be call when somebody will buy tokens from website. This function only delegator.
    *
    * @param _investor - address of investor (who payed)
    * @param _amount - ethereum
    */
    function transferWeb3js(address _investor, uint256 _amount) external onlyOwner
    {
        sell(_investor, _amount);
    }

    /**
    * Function for adding discount
    *
    */
    function withDiscount(uint256 _amount, uint _percent) internal pure
        returns (uint256)
    {
        return ((_amount * _percent) / 100);
    }
}

contract BarbarossaContract is ERC20Extending, BarbarossaCrowdsale
{

    uint public weisRaised; /// количеств эфиров, которые пришли

    function BarbarossaContract() public TokenERC20(1000000000, "BarbarossaInvestCoin", "BRBS") {} //change before send !!!

    
    /**
    * Function payments handler
    *
    */
    function () public payable   //  приход эфиров на счет
    {
        assert(msg.value >= 1 ether / 10);  // проверка что прыслано более чем 0,1 эфир - минимально 5 токенов - 50 баксов
        
        sell(msg.sender, msg.value);
        owner.transfer(msg.value); ///++ отправляет эфир сразу владельцу контракта
        weisRaised = weisRaised.add(msg.value);  /// количеств эфиров, которые пришли - можно к web3js прикрутить
    }
}